using OracleHR.Domain.Enums;

namespace OracleHR.Domain.Entities;

public class Employee
{
    public long EmployeeId { get; set; }
    public string EmpCode { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateTime HireDate { get; set; }
    public string JobTitle { get; set; } = string.Empty;
    public long DepartmentId { get; set; }
    public long? ManagerId { get; set; }
    public decimal BaseSalary { get; set; }
    public EmploymentStatus Status { get; set; } = EmploymentStatus.Active;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // Navigation
    public Department Department { get; set; } = null!;
    public Employee? Manager { get; set; }
    public ICollection<Employee> Subordinates { get; set; } = [];
    public ICollection<SalaryRecord> SalaryRecords { get; set; } = [];
    public ICollection<PerformanceReview> PerformanceReviews { get; set; } = [];
}
