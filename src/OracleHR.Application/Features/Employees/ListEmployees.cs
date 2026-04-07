using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.Domain.Enums;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class ListEmployees
{
    public record Query : IRequest<Result<IReadOnlyList<Dto>>>;

    public record Dto(
        long EmployeeId,
        string EmpCode,
        string FullName,
        string JobTitle,
        string DeptName,
        string Status
    );

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<IReadOnlyList<Dto>>>
    {
        public async Task<Result<IReadOnlyList<Dto>>> Handle(Query request, CancellationToken ct)
        {
            var list = await db.Employees
                .AsNoTracking()
                .OrderBy(e => e.EmployeeId)
                .Select(e => new Dto(
                    e.EmployeeId,
                    e.EmpCode,
                    e.LastName + " " + e.FirstName,
                    e.JobTitle,
                    e.Department.DeptName,
                    e.Status == EmploymentStatus.Active ? "Active"
                        : e.Status == EmploymentStatus.Inactive ? "Inactive"
                        : "Resigned"
                ))
                .ToListAsync(ct);

            return Result.Success<IReadOnlyList<Dto>>(list);
        }
    }
}
