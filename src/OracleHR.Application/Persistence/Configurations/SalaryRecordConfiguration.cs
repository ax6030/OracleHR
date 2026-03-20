using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OracleHR.Domain.Entities;

namespace OracleHR.Application.Persistence.Configurations;

public class SalaryRecordConfiguration : IEntityTypeConfiguration<SalaryRecord>
{
    public void Configure(EntityTypeBuilder<SalaryRecord> builder)
    {
        // 此表在 Oracle 是分區表（EF Core 僅做 CRUD，分區由 SQL 腳本建立）
        builder.ToTable("SALARY_RECORDS");

        // 分區表的 PK 需包含分區鍵（EffectiveDate）
        builder.HasKey(x => new { x.SalaryId, x.EffectiveDate });

        builder.Property(x => x.SalaryId)
            .HasColumnName("SALARY_ID")
            .ValueGeneratedOnAdd();

        builder.Property(x => x.EmployeeId).HasColumnName("EMPLOYEE_ID");

        builder.Property(x => x.EffectiveDate)
            .HasColumnName("EFFECTIVE_DATE")
            .HasColumnType("DATE")
            .IsRequired();

        builder.Property(x => x.BaseSalary)
            .HasColumnName("BASE_SALARY")
            .HasColumnType("NUMBER(12,2)")
            .IsRequired();

        builder.Property(x => x.Bonus)
            .HasColumnName("BONUS")
            .HasColumnType("NUMBER(12,2)")
            .HasDefaultValue(0);

        // VIRTUAL column（Oracle 計算欄位）：不能 INSERT/UPDATE，僅讀取
        builder.Property(x => x.TotalSalary)
            .HasColumnName("TOTAL_SALARY")
            .HasColumnType("NUMBER(12,2)")
            .ValueGeneratedOnAddOrUpdate();

        builder.Property(x => x.Remark)
            .HasColumnName("REMARK")
            .HasColumnType("VARCHAR2(500)");

        builder.Property(x => x.CreatedAt)
            .HasColumnName("CREATED_AT")
            .HasColumnType("DATE")
            .HasDefaultValueSql("SYSDATE");

        builder.HasOne(x => x.Employee)
            .WithMany(x => x.SalaryRecords)
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
