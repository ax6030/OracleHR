using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class GetPerformanceReviews
{
    public record Query(long EmployeeId) : IRequest<Result<IReadOnlyList<Dto>>>;

    public record Dto(
        long ReviewId,
        int ReviewYear,
        int ReviewQuarter,
        decimal Score,
        string Grade,
        string? Comments,
        string ReviewerName,
        DateTime ReviewDate
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

            var reviews = await db.PerformanceReviews
                .AsNoTracking()
                .Where(r => r.EmployeeId == request.EmployeeId)
                .OrderByDescending(r => r.ReviewYear)
                .ThenByDescending(r => r.ReviewQuarter)
                .Select(r => new Dto(
                    r.ReviewId,
                    r.ReviewYear,
                    r.ReviewQuarter,
                    r.Score,
                    r.Grade,
                    r.Comments,
                    r.Reviewer.LastName + " " + r.Reviewer.FirstName,
                    r.ReviewDate
                ))
                .ToListAsync(ct);

            return Result.Success<IReadOnlyList<Dto>>(reviews);
        }
    }
}
