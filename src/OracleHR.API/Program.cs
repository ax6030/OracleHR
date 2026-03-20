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

// ─── 管線設定 ──────────────────────────────────────────────
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();
app.Run();
