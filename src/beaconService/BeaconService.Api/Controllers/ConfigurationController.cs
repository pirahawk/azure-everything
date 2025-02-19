using BeaconService.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class ConfigurationController: ControllerBase{
    private readonly IOptions<BeaconConfigurationModel> beaconConfiguration;
    private readonly ILogger<ConfigurationController> logger;

    public ConfigurationController(IOptions<BeaconConfigurationModel> beaconConfiguration, ILogger<ConfigurationController> logger)
    {
        this.beaconConfiguration = beaconConfiguration;
        this.logger = logger;
    }

    [HttpGet(Name = "GetConfiguration")]
    public IActionResult GetConfiguration(){
        return Ok(beaconConfiguration.Value);
    }
}
