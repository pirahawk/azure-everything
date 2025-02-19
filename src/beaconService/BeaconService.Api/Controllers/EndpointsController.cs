using System.Net;
using BeaconService.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class EndpointsController : ControllerBase
{
    private readonly IOptions<BeaconConfigurationModel> beaconConfiguration;
    private readonly ILogger<EndpointsController> logger;
    private readonly IHttpClientFactory httpClientFactory;

    public EndpointsController(
        IOptions<BeaconConfigurationModel> beaconConfiguration,
        ILogger<EndpointsController> logger,
        IHttpClientFactory httpClientFactory)
    {
        this.beaconConfiguration = beaconConfiguration;
        this.logger = logger;
        this.httpClientFactory = httpClientFactory;
    }

    [HttpGet("{apiEndpointId:int?}", Name = "CallEndpoint")]
    public async Task<IActionResult> CallEndpoint(int? apiEndpointId = 0)
    {
        try
        {
            var httpClient = httpClientFactory.CreateClient($"{BeaconConfigurationModel.ApiHttpClientPrefix}{apiEndpointId}");
            var httpResponseMessage = await httpClient.GetAsync("beacon/ping");
            return httpResponseMessage.IsSuccessStatusCode ? Ok(await httpResponseMessage.Content.ReadAsStringAsync()) : StatusCode((int)httpResponseMessage.StatusCode);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, $"Error trying to Call ApiEndpoint{apiEndpointId}");
        }
        return StatusCode((int)HttpStatusCode.InternalServerError);
    }
}
