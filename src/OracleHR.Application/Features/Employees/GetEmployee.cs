using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class GetEmployee
{
    public record Query(long EmployeeId) : IRequest<Result<Dto>>;

    public record Dto(
        long EmployeeId,
        string EmpCode,
        string FullName,
        string Email,
        string JobTitle,
        string DeptName,
        decimal BaseSalary,
        string Status,
        DateTime HireDate
    );

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<Dto>>
    {
        public async Task<Result<Dto>> Handle(Query request, CancellationToken ct)
        {
            var dto = await db.Employees
                .AsNoTracking()
                .Where(e => e.EmployeeId == request.EmployeeId)
                .Select(e => new Dto(
                    e.EmployeeId,
                    e.EmpCode,
                    e.LastName + " " + e.FirstName,
                    e.Email,
                    e.JobTitle,
                    e.Department.DeptName,
                    e.BaseSalary,
                    e.Status.ToString(),
                    e.HireDate
                ))
                .FirstOrDefaultAsync(ct);

            return dto is null
                ? Result.Failure<Dto>("員工不存在")
                : Result.Success(dto);
        }
    }
}
