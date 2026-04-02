using Microsoft.EntityFrameworkCore;
using OracleHR.Application.Persistence;

var builder = WebApplication.CreateBuilder(args);

// ─── 服務註冊 ──────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "OracleHR API", Version = "v1" });
});

// Oracle EF Core
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseOracle(builder.Configuration.GetConnectionString("Oracle")));

// MediatR（掃描 Application 層所有 Handler）
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(OracleHR.Application.AssemblyMarker).Assembly));

// CORS：允許 Vue 開發伺服器（5173）與正式容器（6001）跨來源存取
builder.Services.AddCors(options =>
{
    options.AddPolicy("VueFrontend", policy =>
        policy.WithOrigins(
                "http://localhost:5173",   // Vite 開發模式
                "http://localhost:6001"    // Docker 正式環境
              )
              .AllowAnyHeader()
              .AllowAnyMethod());
});

// ─── 管線設定 ──────────────────────────────────────────────
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// CORS 必須在 UseAuthorization 之前
app.UseCors("VueFrontend");
app.UseAuthorization();
app.MapControllers();
app.Run();
