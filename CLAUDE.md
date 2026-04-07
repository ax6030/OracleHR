# CLAUDE.md

> 本檔案為 Claude Code 的專案記憶體，每次 session 啟動時自動載入。
> 保持在 300 行以內，不放 code style 細節（那是 .editorconfig 的工作）。

---

## 🏗️ 技術棧

| 層次 | 技術 |
|------|------|
| 後端框架 | ASP.NET Core (.NET 9) |
| 語言 | C# 13 |
| 前端 | Vue 3 + TypeScript + Vite |
| 資料庫 | Oracle XE 21c（PDB: XEPDB1） |
| ORM | Entity Framework Core 9 (code-first) |
| CQRS Mediator | MediatR |
| 容器 | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| 測試 | xUnit v2 + Testcontainers |

---

## 📁 專案結構（Clean Architecture + Vertical Slice 混合）

```
src/
├── OracleHR.Domain/
│   ├── Entities/          # Employee, Department, SalaryRecord, PerformanceReview
│   └── Enums/             # EmploymentStatus
│
├── OracleHR.Application/  # ★ Vertical Slice
│   ├── Features/
│   │   ├── Employees/     # GetEmployee, ListEmployees, CreateEmployee,
│   │   │                  # UpdateEmployee, DeleteEmployee,
│   │   │                  # GetSalaryRecords, GetPerformanceReviews
│   │   └── Departments/   # GetDepartmentTree, ListDepartments
│   ├── Persistence/       # AppDbContext 介面（IAppDbContext）
│   └── Common/
│       └── Models/        # Result<T>
│
├── OracleHR.Infrastructure/
│   └── Persistence/
│       ├── AppDbContext.cs
│       └── Configurations/ # EF Fluent API（每個 Entity 一檔）
│
├── OracleHR.SharedKernel/
│   └── Models/            # Result<T> 實作
│
├── OracleHR.API/
│   ├── Controllers/       # EmployeesController, DepartmentsController
│   └── Program.cs
│
└── OracleHR.Web/          # Vue 3 + TypeScript
    └── src/
        ├── views/         # DepartmentTreeView, EmployeeManageView
        ├── components/    # DeptNode
        ├── stores/        # employeeStore（Pinia）
        ├── services/      # api.ts（axios）
        ├── router/        # index.ts
        └── types.ts

sql/
├── 00_init.sh             # Docker 初始化入口（以 APP_USER 執行）
└── scripts/               # 01~08 依序執行
    ├── 01_sequences.sql
    ├── 02_tables.sql
    ├── 03_triggers.sql    # trg_employee_code 自動產生 EmpCode
    ├── 04_stored_procedures.sql
    ├── 05_materialized_view.sql
    ├── 06_connect_by_demo.sql
    ├── 07_flashback_demo.sql
    └── 08_seed_data.sql
```

---

## ✍️ Slice 標準寫法

**Query（唯讀）：**

```csharp
// Features/Employees/GetEmployee.cs
public static class GetEmployee
{
    public record Query(long EmployeeId) : IRequest<Result<Dto>>;

    public record Dto(long EmployeeId, string FullName, string Email, string JobTitle);

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<Dto>>
    {
        public async Task<Result<Dto>> Handle(Query request, CancellationToken ct)
        {
            var dto = await db.Employees
                .AsNoTracking()
                .Where(e => e.EmployeeId == request.EmployeeId)
                .Select(e => new Dto(e.EmployeeId, e.FirstName + " " + e.LastName, e.Email, e.JobTitle))
                .FirstOrDefaultAsync(ct);

            return dto is null
                ? Result.Failure<Dto>("員工不存在")
                : Result.Success(dto);
        }
    }
}
```

**Command（寫入）：**

```csharp
// Features/Employees/CreateEmployee.cs
public static class CreateEmployee
{
    public record Command(string FirstName, string LastName, string Email,
        DateTime HireDate, string JobTitle, long DepartmentId, decimal BaseSalary
    ) : IRequest<Result<long>>;

    public class Handler(AppDbContext db) : IRequestHandler<Command, Result<long>>
    {
        public async Task<Result<long>> Handle(Command request, CancellationToken ct)
        {
            if (await db.Employees.AnyAsync(e => e.Email == request.Email, ct))
                return Result.Failure<long>("Email 已被使用");

            var emp = new Employee { /* ... */ };
            db.Employees.Add(emp);
            await db.SaveChangesAsync(ct);
            return Result.Success(emp.EmployeeId);
        }
    }
}
```

**Controller（薄，只轉發）：**

```csharp
[HttpGet("{id:long}")]
public async Task<IActionResult> Get(long id, CancellationToken ct)
{
    var result = await mediator.Send(new GetEmployee.Query(id), ct);
    return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
}
```

---

## 🎯 架構規則

### 相依性方向
```
Domain ← Application ← Infrastructure
                     ← API
SharedKernel ← 所有層皆可引用
```

### 核心規範
- Feature 資料夾 = 業務功能（禁止建 Commands/、Handlers/、DTOs/ 根目錄）
- Handler **直接注入 `AppDbContext`**，不包 Repository 層
- Controller 只能呼叫 `mediator.Send()`，禁止寫業務邏輯
- 回傳錯誤用 `Result<T>`，不用 exception 控制流程
- Oracle EmpCode 由 `trg_employee_code` trigger 自動產生，不在 C# 設定

---

## 🗄️ Oracle 資料庫規範

```csharp
// EF Fluent API 設定 Oracle 型別
builder.Property(x => x.HireDate).HasColumnType("DATE");
builder.Property(x => x.BaseSalary).HasColumnType("NUMBER(10,2)");
// Oracle 序列 + trigger 自動 PK
builder.Property(x => x.EmployeeId).UseOracleIdentityColumn();
// 唯讀查詢一律 AsNoTracking
```

**Oracle 特有功能：**
- `CONNECT BY PRIOR` — 部門組織樹（`GetDepartmentTree`）
- Flashback Query — 歷史資料查詢（`07_flashback_demo.sql`）
- Materialized View — 快取彙總資料（`05_materialized_view.sql`）
- `NLS_DATE_FORMAT` — 日期格式注意 `TO_DATE`/`TO_CHAR`

**連線字串：**
```
User Id=${APP_USER};Password=${APP_PASSWORD};Data Source=oracle-db:1521/XEPDB1;
```

---

## 🚀 常用指令

```bash
# 後端
dotnet build
dotnet test
dotnet ef migrations add <Name> --project src/OracleHR.Infrastructure --startup-project src/OracleHR.API
dotnet ef database update --project src/OracleHR.Infrastructure --startup-project src/OracleHR.API

# 前端（src/OracleHR.Web/）
npm run dev        # localhost:5173
npm run build
npm run lint

# Docker（root 目錄）
docker compose up -d
docker compose up --build -d
docker compose logs -f api
```

---

## ⚗️ 測試規範

```csharp
// 命名：MethodName_Condition_ExpectedResult
public async Task Handle_WhenEmailDuplicated_ShouldReturnFailure()
{
    // Arrange  /  Act  /  Assert
}
```

- Unit Test：直接 new Handler，傳入 in-memory DbContext
- Integration Test：Testcontainers（真實 Oracle container）
- `[Fact]` 單一情境，`[Theory][InlineData]` 多輸入情境

---

## 🐳 Docker 服務

| 服務 | Image | 主機 Port | 說明 |
|------|-------|-----------|------|
| oracle-db | gvenzl/oracle-xe:21-slim | 6521 | PDB: XEPDB1 |
| cloudbeaver | dbeaver/cloudbeaver | 6080 | Web DB UI |
| api | OracleHR.API | 6000 | ASP.NET Core |
| web | OracleHR.Web + Nginx | 6001 | Vue 3 前端 |

- 機密放 `.env`（不進 Git），範本放 `.env.example`
- `00_init.sh` 以 APP_USER 身分連 XEPDB1 依序執行 scripts/01~08

---

## 🔄 CI/CD（GitHub Actions）

觸發：push `main`/`develop`，PR to `main`

步驟：`restore` → `build` → `test` → 前端 `lint`+`build` → Docker build

Branch：`main` / `develop` / `feature/*` / `fix/*`

---

## 🔍 關鍵文件

- DB Schema：`sql/scripts/02_tables.sql`
- Seed Data：`sql/scripts/08_seed_data.sql`
- API 規格：`/swagger`
- 環境設定：`.env.example`
