using MediatR;
using Microsoft.AspNetCore.Mvc;
using OracleHR.Application.Features.Employees;

namespace OracleHR.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmployeesController(IMediator mediator) : ControllerBase
{
    // GET /api/employees
    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var result = await mediator.Send(new ListEmployees.Query(), ct);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    // GET /api/employees/{id}
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetEmployee.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }

    // POST /api/employees
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEmployee.Command cmd, CancellationToken ct)
    {
        var result = await mediator.Send(cmd, ct);
        return result.IsSuccess
            ? CreatedAtAction(nameof(Get), new { id = result.Value }, new { employeeId = result.Value })
            : BadRequest(result.Error);
    }

    // PUT /api/employees/{id}
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateEmployee.Command cmd, CancellationToken ct)
    {
        if (id != cmd.EmployeeId) return BadRequest("路徑 ID 與 body ID 不一致");
        var result = await mediator.Send(cmd, ct);
        return result.IsSuccess ? NoContent() : NotFound(result.Error);
    }

    // DELETE /api/employees/{id}
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new DeleteEmployee.Command(id), ct);
        return result.IsSuccess ? NoContent() : NotFound(result.Error);
    }

    // GET /api/employees/{id}/salaries
    [HttpGet("{id:long}/salaries")]
    public async Task<IActionResult> GetSalaries(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetSalaryRecords.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }

    // GET /api/employees/{id}/reviews
    [HttpGet("{id:long}/reviews")]
    public async Task<IActionResult> GetReviews(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetPerformanceReviews.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }
}
