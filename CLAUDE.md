# CLAUDE.md

> 本檔案為 Claude Code 的專案記憶體，每次 session 啟動時自動載入。
> 保持在 300 行以內，不放 code style 細節（那是 .editorconfig 的工作）。

---

## 🏗️ 技術棧

| 層次 | 技術 |
|------|------|
| 後端框架 | ASP.NET Core (.NET 9) |
| 語言 | C# 13 |
| 前端 | React 18 + TypeScript + Vite |
| 主要資料庫 | SQL Server 2022 |
| 學習用資料庫 | MySQL 8.x |
| ORM | Entity Framework Core 9 (code-first) |
| CQRS Mediator | MediatR |
| 容器 | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| 測試 | xUnit v2 + Testcontainers |

---

## 📁 專案結構（Clean Architecture + Vertical Slice 混合）

```
src/
├── YourApp.Domain/              # 純 C#，不相依任何外層
│   ├── Entities/                # 核心實體（Device, ModbusConfig...）
│   ├── ValueObjects/            # 值物件（IpAddress, RegisterRange...）
│   └── Enums/
│
├── YourApp.Application/         # ★ Vertical Slice 在此層切分
│   ├── Features/                # 依功能垂直切，不依技術類型切
│   │   ├── ModbusConfig/
│   │   │   ├── GetModbusConfig.cs      # Query + Dto + Handler
│   │   │   ├── UpdateModbusConfig.cs   # Command + Validator + Handler
│   │   │   └── CreateModbusConfig.cs
│   │   ├── Device/
│   │   │   ├── GetDevices.cs
│   │   │   ├── CreateDevice.cs
│   │   │   └── SyncDeviceTags.cs
│   │   ├── Chart/
│   │   └── Log/
│   └── Common/                  # 跨 Slice 共用，不放業務邏輯
│       ├── Behaviours/          # MediatR Pipeline（Validation、Logging）
│       ├── Interfaces/          # IModbusDeviceMapper 等跨層介面
│       └── Models/              # Result<T>、PagedList<T>
│
├── YourApp.Infrastructure/      # Application 介面的實作
│   ├── Persistence/
│   │   ├── AppDbContext.cs
│   │   ├── Configurations/      # EF Fluent API（每個 Entity 一個檔案）
│   │   └── Migrations/
│   └── Services/
│       └── Modbus/              # IModbusDeviceMapper 實作、Register mapping
│
├── YourApp.SharedKernel/        # 跨專案共用輔助（無業務邏輯）
│   ├── Extensions/
│   ├── Helpers/
│   └── Guards/
│
├── YourApp.API/                 # 組合根，薄 Controller
│   ├── Controllers/             # 只做 Send(command) → ToActionResult()
│   ├── Middleware/
│   └── Program.cs
│
└── YourApp.Web/                 # React + TypeScript
    └── src/
        ├── features/            # 前端也按功能切（對應後端 Feature）
        ├── components/
        ├── hooks/
        └── services/

tests/
├── YourApp.UnitTests/
├── YourApp.IntegrationTests/    # Testcontainers 真實 DB
└── YourApp.ArchTests/           # NetArchTest 架構守門
```

---

## ✍️ Slice 標準寫法

**一個 Use Case = 一個 `.cs` 檔案，static class 包住所有內容：**

```csharp
// Features/ModbusConfig/GetModbusConfig.cs
public static class GetModbusConfig
{
    public record Query(int DeviceId) : IRequest<Result<Dto>>;

    public record Dto(int DeviceId, string IpAddress, int Port, bool IsEnabled);

    public class Handler(AppDbContext db) : IRequestHandler<Query, Result<Dto>>
    {
        public async Task<Result<Dto>> Handle(Query request, CancellationToken ct)
        {
            var dto = await db.ModbusConfigs
                .AsNoTracking()
                .Where(x => x.DeviceId == request.DeviceId)
                .Select(x => new Dto(x.DeviceId, x.IpAddress, x.Port, x.IsEnabled))
                .FirstOrDefaultAsync(ct);

            return dto is null
                ? Result.Failure<Dto>("設備不存在")
                : Result.Success(dto);
        }
    }
}
```

**含 Validator 的 Command：**

```csharp
// Features/ModbusConfig/UpdateModbusConfig.cs
public static class UpdateModbusConfig
{
    public record Command(int DeviceId, string IpAddress, int Port) : IRequest<Result>;

    public class Validator : AbstractValidator<Command>
    {
        public Validator()
        {
            RuleFor(x => x.IpAddress).NotEmpty();
            RuleFor(x => x.Port).InclusiveBetween(1, 65535);
        }
    }

    public class Handler(AppDbContext db) : IRequestHandler<Command, Result>
    {
        public async Task<Result> Handle(Command request, CancellationToken ct)
        {
            var config = await db.ModbusConfigs
                .FirstOrDefaultAsync(x => x.DeviceId == request.DeviceId, ct);

            if (config is null) return Result.Failure("設備不存在");
            config.IpAddress = request.IpAddress;
            config.Port = request.Port;
            await db.SaveChangesAsync(ct);
            return Result.Success();
        }
    }
}
```

**Controller 只做轉發（薄 Controller）：**

```csharp
[HttpGet("{deviceId}")]
public async Task<IActionResult> Get(int deviceId)
    => (await _mediator.Send(new GetModbusConfig.Query(deviceId))).ToActionResult();
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
- Feature 資料夾 = 業務功能，不是技術類型（禁止建 Commands/、Handlers/、DTOs/ 根目錄）
- Handler **直接注入 `AppDbContext`**，不再包 Repository 層（除非邏輯跨多 Slice 重複才抽）
- 跨 Slice 共用的介面（`IModbusDeviceMapper` 等）放 `Common/Interfaces/`，實作在 Infrastructure
- Domain Entity 不知道 EF Core 的存在
- Controller 只能呼叫 `_mediator.Send()`，禁止寫業務邏輯
- 回傳錯誤用 `Result<T>`，不用 exception 控制流程
- 禁止 `DateTime.Now`，一律注入 `TimeProvider`

---

## 🗄️ 資料庫規範

### EF Core（SQL Server 主要）
```csharp
// Fluent API，放 Infrastructure/Persistence/Configurations/
public class ModbusConfigConfiguration : IEntityTypeConfiguration<ModbusConfig>
{
    public void Configure(EntityTypeBuilder<ModbusConfig> builder)
    {
        builder.ToTable("ModbusConfigs");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.IpAddress).HasMaxLength(50).IsRequired();
    }
}
// 唯讀查詢一律 AsNoTracking
// 分頁：Skip((page-1)*size).Take(size)
```

### MySQL（學習對照）
```csharp
// 與 SQL Server 差異：
// - DateTime 需明確指定 .HasColumnType("datetime(6)")
// - 字串比較預設不分大小寫（注意 collation）
// 連線字串：Server=mysql;Port=3306;Database=MyDb;Uid=root;Pwd=...
```

### Migration
- 命名描述性：`AddModbusConfigIpAddressIndex`，不放業務邏輯
- 指令：`--project src/YourApp.Infrastructure --startup-project src/YourApp.API`

---

## 🚀 常用指令

```bash
# 後端
dotnet build
dotnet test
dotnet ef migrations add <Name> --project src/YourApp.Infrastructure --startup-project src/YourApp.API
dotnet ef database update --project src/YourApp.Infrastructure --startup-project src/YourApp.API

# 前端（src/YourApp.Web/）
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
public async Task Handle_WhenDeviceNotFound_ShouldReturnFailure()
{
    // Arrange  /  Act  /  Assert（各段加註解）
}
```

- Unit Test：直接 new Handler，傳入 mock 或 in-memory DbContext
- Integration Test：Testcontainers（真實 SQL Server container，不用 in-memory DB）
- `[Fact]` 單一情境，`[Theory][InlineData]` 多輸入情境

---

## 🐳 Docker

```
services: sqlserver(1433)  mysql(3306)  api(5000)  web(3000)
```
- 機密放 `.env`（不進 Git），範本放 `.env.example`
- 後端 Multi-stage build，runtime image 用 `mcr.microsoft.com/dotnet/aspnet`
- 前端 build 後用 Nginx 靜態服務

---

## 🔄 CI/CD（GitHub Actions）

觸發：push `main`/`develop`，PR to `main`

步驟：`restore` → `build` → `test`（含 Testcontainers）→ 前端 `lint`+`build` → Docker build

Branch：`main` / `develop` / `feature/*` / `fix/*`

---

## 🔍 關鍵文件

- 架構決策：`docs/ARCHITECTURE.md`（架構疑問先讀）
- DB Schema：`docs/DATABASE.md`
- API 規格：`/swagger` 或 `docs/API.md`
- 環境設定：`.env.example`
