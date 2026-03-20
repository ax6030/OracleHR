namespace OracleHR.Domain.Entities;

public class Department
{
    public long DepartmentId { get; set; }
    public string DeptName { get; set; } = string.Empty;
    public long? ParentDeptId { get; set; }
    public long? ManagerId { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation
    public Department? Parent { get; set; }
    public ICollection<Department> Children { get; set; } = [];
    public Employee? Manager { get; set; }
    public ICollection<Employee> Employees { get; set; } = [];
}
