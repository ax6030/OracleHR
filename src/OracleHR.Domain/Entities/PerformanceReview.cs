namespace OracleHR.Domain.Entities;

public class PerformanceReview
{
    public long ReviewId { get; set; }
    public long EmployeeId { get; set; }
    public long ReviewerId { get; set; }
    public int ReviewYear { get; set; }
    public int ReviewQuarter { get; set; }
    public decimal Score { get; set; }
    public string Grade { get; set; } = "B";   // S/A/B/C/D
    public string? Comments { get; set; }       // 對應 Oracle CLOB
    public DateTime ReviewDate { get; set; }

    public Employee Employee { get; set; } = null!;
    public Employee Reviewer { get; set; } = null!;
}
