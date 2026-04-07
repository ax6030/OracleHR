using MediatR;
using Microsoft.AspNetCore.Mvc;
using OracleHR.Application.Features.Departments;

namespace OracleHR.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DepartmentsController(IMediator mediator) : ControllerBase
{
    // GET /api/departments
    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var result = await mediator.Send(new ListDepartments.Query(), ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    // GET /api/departments/tree（Oracle CONNECT BY）
    [HttpGet("tree")]
    public async Task<IActionResult> GetTree(CancellationToken ct)
    {
        var result = await mediator.Send(new GetDepartmentTree.Query(), ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }
}
