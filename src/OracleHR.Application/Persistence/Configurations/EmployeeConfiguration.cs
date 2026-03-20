using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OracleHR.Domain.Entities;
using OracleHR.Domain.Enums;

namespace OracleHR.Application.Persistence.Configurations;

public class EmployeeConfiguration : IEntityTypeConfiguration<Employee>
{
    public void Configure(EntityTypeBuilder<Employee> builder)
    {
        builder.ToTable("EMPLOYEES");
        builder.HasKey(x => x.EmployeeId);

        builder.Property(x => x.EmployeeId)
            .HasColumnName("EMPLOYEE_ID")
            .ValueGeneratedOnAdd();

        builder.Property(x => x.EmpCode)
            .HasColumnName("EMP_CODE")
            .HasColumnType("VARCHAR2(20)")
            .IsRequired();

        builder.Property(x => x.FirstName)
            .HasColumnName("FIRST_NAME")
            .HasColumnType("VARCHAR2(50)")
            .IsRequired();

        builder.Property(x => x.LastName)
            .HasColumnName("LAST_NAME")
            .HasColumnType("VARCHAR2(50)")
            .IsRequired();

        builder.Property(x => x.Email)
            .HasColumnName("EMAIL")
            .HasColumnType("VARCHAR2(100)")
            .IsRequired();

        builder.Property(x => x.Phone)
            .HasColumnName("PHONE")
            .HasColumnType("VARCHAR2(20)");

        builder.Property(x => x.HireDate)
            .HasColumnName("HIRE_DATE")
            .HasColumnType("DATE")
            .IsRequired();

        builder.Property(x => x.JobTitle)
            .HasColumnName("JOB_TITLE")
            .HasColumnType("VARCHAR2(100)")
            .IsRequired();

        builder.Property(x => x.DepartmentId).HasColumnName("DEPARTMENT_ID");
        builder.Property(x => x.ManagerId).HasColumnName("MANAGER_ID");

        builder.Property(x => x.BaseSalary)
            .HasColumnName("BASE_SALARY")
            .HasColumnType("NUMBER(12,2)")
            .IsRequired();

        // Oracle CHECK 對應：將 Enum 存為字串
        builder.Property(x => x.Status)
            .HasColumnName("STATUS")
            .HasColumnType("VARCHAR2(20)")
            .HasConversion(
                v => v.ToString().ToUpper(),
                v => Enum.Parse<EmploymentStatus>(v, true))
            .HasDefaultValue(EmploymentStatus.Active);

        builder.Property(x => x.CreatedAt)
            .HasColumnName("CREATED_AT")
            .HasColumnType("DATE")
            .HasDefaultValueSql("SYSDATE");

        builder.Property(x => x.UpdatedAt)
            .HasColumnName("UPDATED_AT")
            .HasColumnType("DATE")
            .HasDefaultValueSql("SYSDATE");

        // 唯一索引
        builder.HasIndex(x => x.EmpCode).IsUnique();
        builder.HasIndex(x => x.Email).IsUnique();

        // FK：部門
        builder.HasOne(x => x.Department)
            .WithMany(x => x.Employees)
            .HasForeignKey(x => x.DepartmentId)
            .OnDelete(DeleteBehavior.Restrict);

        // FK：直屬主管（自我參照）
        builder.HasOne(x => x.Manager)
            .WithMany(x => x.Subordinates)
            .HasForeignKey(x => x.ManagerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
