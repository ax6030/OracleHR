using MediatR;
using Microsoft.AspNetCore.Mvc;
using OracleHR.Application.Features.Departments;

namespace OracleHR.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DepartmentsController(IMediator mediator) : ControllerBase
{
    /// <summary>
    /// 取得部門組織樹（使用 Oracle CONNECT BY 原生語法）
    /// </summary>
    [HttpGet("tree")]
    public async Task<IActionResult> GetTree(CancellationToken ct)
    {
        var result = await mediator.Send(new GetDepartmentTree.Query(), ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }
}
