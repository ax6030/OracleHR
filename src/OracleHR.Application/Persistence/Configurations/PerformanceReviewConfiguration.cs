using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OracleHR.Domain.Entities;

namespace OracleHR.Application.Persistence.Configurations;

public class PerformanceReviewConfiguration : IEntityTypeConfiguration<PerformanceReview>
{
    public void Configure(EntityTypeBuilder<PerformanceReview> builder)
    {
        builder.ToTable("PERFORMANCE_REVIEWS");
        builder.HasKey(x => x.ReviewId);

        builder.Property(x => x.ReviewId)
            .HasColumnName("REVIEW_ID")
            .ValueGeneratedOnAdd();

        builder.Property(x => x.EmployeeId).HasColumnName("EMPLOYEE_ID");
        builder.Property(x => x.ReviewerId).HasColumnName("REVIEWER_ID");
        builder.Property(x => x.ReviewYear).HasColumnName("REVIEW_YEAR");
        builder.Property(x => x.ReviewQuarter).HasColumnName("REVIEW_QUARTER");

        builder.Property(x => x.Score)
            .HasColumnName("SCORE")
            .HasColumnType("NUMBER(5,2)");

        builder.Property(x => x.Grade)
            .HasColumnName("GRADE")
            .HasColumnType("VARCHAR2(2)")
            .HasDefaultValue("B");

        // Oracle CLOB → C# string
        builder.Property(x => x.Comments)
            .HasColumnName("COMMENTS")
            .HasColumnType("CLOB");

        builder.Property(x => x.ReviewDate)
            .HasColumnName("REVIEW_DATE")
            .HasColumnType("DATE")
            .HasDefaultValueSql("SYSDATE");

        // 唯一：同一員工同一季只能一筆考核
        builder.HasIndex(x => new { x.EmployeeId, x.ReviewYear, x.ReviewQuarter })
            .IsUnique()
            .HasDatabaseName("UQ_REVIEW_PERIOD");

        builder.HasOne(x => x.Employee)
            .WithMany(x => x.PerformanceReviews)
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Reviewer)
            .WithMany()
            .HasForeignKey(x => x.ReviewerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
