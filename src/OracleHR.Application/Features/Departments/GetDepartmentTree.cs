using MediatR;
using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;
using OracleHR.SharedKernel.Models;

namespace OracleHR.Application.Features.Departments;

/// <summary>
/// 查詢部門組織樹
/// 使用 Oracle 原生 CONNECT BY 語法（EF Core 原生 SQL）
/// </summary>
public static class GetDepartmentTree
{
    public record Query : IRequest<Result<List<DeptNodeDto>>>;

    public record DeptNodeDto(
        long DepartmentId,
        string DeptName,
        long? ParentDeptId,
        int Depth,
        string FullPath,
        bool IsLeaf
    );

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<List<DeptNodeDto>>>
    {
        public async Task<Result<List<DeptNodeDto>>> Handle(Query request, CancellationToken ct)
        {
            // Oracle CONNECT BY 原生查詢（EF Core 無法生成此語法）
            const string sql = """
                SELECT
                    department_id        AS "DepartmentId",
                    dept_name            AS "DeptName",
                    parent_dept_id       AS "ParentDeptId",
                    LEVEL                AS "Depth",
                    SYS_CONNECT_BY_PATH(dept_name, ' > ')  AS "FullPath",
                    CONNECT_BY_ISLEAF   AS "IsLeaf"
                FROM departments
                START WITH parent_dept_id IS NULL
                CONNECT BY PRIOR department_id = parent_dept_id
                ORDER SIBLINGS BY dept_name
                """;

            var result = await db.Database
                .SqlQueryRaw<DeptNodeDto>(sql)
                .ToListAsync(ct);

            return Result.Success(result);
        }
    }
}
