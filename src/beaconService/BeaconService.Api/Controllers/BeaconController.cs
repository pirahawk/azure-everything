using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class BeaconController : ControllerBase
{
    private readonly IOptions<BeaconConfigurationModel> beaconConfiguration;
    private readonly ILogger<BeaconController> logger;

    public BeaconController(
        IOptions<BeaconConfigurationModel> beaconConfiguration, 
        ILogger<BeaconController> logger
    )
    {
        this.beaconConfiguration = beaconConfiguration;
        this.logger = logger;
    }

    [HttpGet("ping", Name = "BeaconPing")]
    public async Task<IActionResult> Ping(){
        logger.LogInformation($"Ping Request Received for: {beaconConfiguration.Value.ServiceName}");
        return await Task.FromResult(Ok($"Ping Success: {beaconConfiguration.Value.ServiceName}"));
    }
}
