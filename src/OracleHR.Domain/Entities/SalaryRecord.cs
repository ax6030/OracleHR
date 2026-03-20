namespace OracleHR.Domain.Entities;

public class SalaryRecord
{
    public long SalaryId { get; set; }
    public long EmployeeId { get; set; }
    public DateTime EffectiveDate { get; set; }  // 分區鍵（依年份分區）
    public decimal BaseSalary { get; set; }
    public decimal Bonus { get; set; }
    // TotalSalary 為 Oracle VIRTUAL column，EF Core 映射為唯讀
    public decimal TotalSalary { get; set; }
    public string? Remark { get; set; }
    public DateTime CreatedAt { get; set; }

    public Employee Employee { get; set; } = null!;
}
