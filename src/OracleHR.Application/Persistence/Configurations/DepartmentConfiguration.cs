using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OracleHR.Domain.Entities;

namespace OracleHR.Application.Persistence.Configurations;

public class DepartmentConfiguration : IEntityTypeConfiguration<Department>
{
    public void Configure(EntityTypeBuilder<Department> builder)
    {
        // Oracle 表名大寫慣例
        builder.ToTable("DEPARTMENTS");
        builder.HasKey(x => x.DepartmentId);

        // Oracle GENERATED AS IDENTITY（對應 Sequence 機制）
        builder.Property(x => x.DepartmentId)
            .HasColumnName("DEPARTMENT_ID")
            .ValueGeneratedOnAdd();

        builder.Property(x => x.DeptName)
            .HasColumnName("DEPT_NAME")
            .HasColumnType("VARCHAR2(100)")
            .IsRequired();

        builder.Property(x => x.ParentDeptId).HasColumnName("PARENT_DEPT_ID");
        builder.Property(x => x.ManagerId).HasColumnName("MANAGER_ID");

        builder.Property(x => x.CreatedAt)
            .HasColumnName("CREATED_AT")
            .HasColumnType("DATE")
            .HasDefaultValueSql("SYSDATE");

        // 自我參照（組織樹）
        builder.HasOne(x => x.Parent)
            .WithMany(x => x.Children)
            .HasForeignKey(x => x.ParentDeptId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
