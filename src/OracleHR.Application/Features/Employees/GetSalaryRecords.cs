using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class GetSalaryRecords
{
    public record Query(long EmployeeId) : IRequest<Result<IReadOnlyList<Dto>>>;

    public record Dto(
        long SalaryId,
        DateTime EffectiveDate,
        decimal BaseSalary,
        decimal Bonus,
        decimal TotalSalary,
        string? Remark
    );

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<IReadOnlyList<Dto>>>
    {
        public async Task<Result<IReadOnlyList<Dto>>> Handle(Query request, CancellationToken ct)
        {
            var exists = await db.Employees
                .AsNoTracking()
                .AnyAsync(e => e.EmployeeId == request.EmployeeId, ct);

            if (!exists)
                return Result.Failure<IReadOnlyList<Dto>>("員工不存在");

            var records = await db.SalaryRecords
                .AsNoTracking()
                .Where(s => s.EmployeeId == request.EmployeeId)
                .OrderByDescending(s => s.EffectiveDate)
                .Select(s => new Dto(
                    s.SalaryId,
                    s.EffectiveDate,
                    s.BaseSalary,
                    s.Bonus,
                    s.TotalSalary,
                    s.Remark
                ))
                .ToListAsync(ct);

            return Result.Success<IReadOnlyList<Dto>>(records);
        }
    }
}
