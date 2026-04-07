using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Departments;

public static class ListDepartments
{
    public record Query : IRequest<Result<IReadOnlyList<Dto>>>;

    public record Dto(long DepartmentId, string DeptName);

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<IReadOnlyList<Dto>>>
    {
        public async Task<Result<IReadOnlyList<Dto>>> Handle(Query request, CancellationToken ct)
        {
            var list = await db.Departments
                .AsNoTracking()
                .OrderBy(d => d.DepartmentId)
                .Select(d => new Dto(d.DepartmentId, d.DeptName))
                .ToListAsync(ct);

            return Result.Success<IReadOnlyList<Dto>>(list);
        }
    }
}
