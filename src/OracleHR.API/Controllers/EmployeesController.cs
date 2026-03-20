using MediatR;
using Microsoft.AspNetCore.Mvc;
using OracleHR.Application.Features.Employees;
using OracleHR.SharedKernel.Models;

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
}
