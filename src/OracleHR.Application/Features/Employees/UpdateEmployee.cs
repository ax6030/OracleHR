using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.Domain.Enums;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class UpdateEmployee
{
    public record Command(
        long EmployeeId,
        string FirstName,
        string LastName,
        string Email,
        string? Phone,
        string JobTitle,
        long DepartmentId,
        long? ManagerId,
        decimal BaseSalary,
        EmploymentStatus Status
    ) : IRequest<Result>;

    public class Handler(AppDbContext db) : IRequestHandler<Command, Result>
    {
        public async Task<Result> Handle(Command request, CancellationToken ct)
        {
            var emp = await db.Employees
                .FirstOrDefaultAsync(e => e.EmployeeId == request.EmployeeId, ct);
            if (emp is null)
                return Result.Failure("員工不存在");

            var deptExists = await db.Departments
                .AnyAsync(d => d.DepartmentId == request.DepartmentId, ct);
            if (!deptExists)
                return Result.Failure("部門不存在");

            var emailTaken = await db.Employees
                .AnyAsync(e => e.Email == request.Email && e.EmployeeId != request.EmployeeId, ct);
            if (emailTaken)
                return Result.Failure("Email 已被其他員工使用");

            emp.FirstName    = request.FirstName;
            emp.LastName     = request.LastName;
            emp.Email        = request.Email;
            emp.Phone        = request.Phone;
            emp.JobTitle     = request.JobTitle;
            emp.DepartmentId = request.DepartmentId;
            emp.ManagerId    = request.ManagerId;
            emp.BaseSalary   = request.BaseSalary;
            emp.Status       = request.Status;

            await db.SaveChangesAsync(ct);
            return Result.Success();
        }
    }
}
