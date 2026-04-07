using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.Domain.Entities;
using OracleHR.Domain.Enums;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Employees;

public static class CreateEmployee
{
    public record Command(
        string FirstName,
        string LastName,
        string Email,
        string? Phone,
        DateTime HireDate,
        string JobTitle,
        long DepartmentId,
        long? ManagerId,
        decimal BaseSalary
    ) : IRequest<Result<long>>;

    public class Handler(AppDbContext db) : IRequestHandler<Command, Result<long>>
    {
        public async Task<Result<long>> Handle(Command request, CancellationToken ct)
        {
            var deptExists = await db.Departments
                .AnyAsync(d => d.DepartmentId == request.DepartmentId, ct);
            if (!deptExists)
                return Result.Failure<long>("部門不存在");

            if (await db.Employees.AnyAsync(e => e.Email == request.Email, ct))
                return Result.Failure<long>("Email 已被使用");

            var emp = new Employee
            {
                FirstName    = request.FirstName,
                LastName     = request.LastName,
                Email        = request.Email,
                Phone        = request.Phone,
                HireDate     = request.HireDate,
                JobTitle     = request.JobTitle,
                DepartmentId = request.DepartmentId,
                ManagerId    = request.ManagerId,
                BaseSalary   = request.BaseSalary,
                Status       = EmploymentStatus.Active,
                // EmpCode 由 Oracle trigger trg_employee_code 自動產生
            };

            db.Employees.Add(emp);
            await db.SaveChangesAsync(ct);
            return Result.Success(emp.EmployeeId);
        }
    }
}
