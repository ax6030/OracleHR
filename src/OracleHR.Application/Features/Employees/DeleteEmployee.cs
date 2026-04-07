using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class DeleteEmployee
{
    public record Command(long EmployeeId) : IRequest<Result>;

    public class Handler(AppDbContext db) : IRequestHandler<Command, Result>
    {
        public async Task<Result> Handle(Command request, CancellationToken ct)
        {
            var emp = await db.Employees
                .FirstOrDefaultAsync(e => e.EmployeeId == request.EmployeeId, ct);
            if (emp is null)
                return Result.Failure("員工不存在");

            db.Employees.Remove(emp);
            await db.SaveChangesAsync(ct);
            return Result.Success();
        }
    }
}
