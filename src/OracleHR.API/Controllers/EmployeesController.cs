using MediatR;
using Microsoft.AspNetCore.Mvc;
using OracleHR.Application.Features.Employees;

namespace OracleHR.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmployeesController(IMediator mediator) : ControllerBase
{
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetEmployee.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }

    [HttpGet("{id:long}/salaries")]
    public async Task<IActionResult> GetSalaries(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetSalaryRecords.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }

    [HttpGet("{id:long}/reviews")]
    public async Task<IActionResult> GetReviews(long id, CancellationToken ct)
    {
        var result = await mediator.Send(new GetPerformanceReviews.Query(id), ct);
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }
}
