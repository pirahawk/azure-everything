using System.Net;
using BeaconService.Api.Models;
using BeaconService.Api.Utils;
using Microsoft;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class CosmosDbController(
    IOptions<BeaconConfigurationModel> beaconConfiguration,
    CosmosDbConnectionFactory cosmosDbConnectionFactory,
    ILogger<CosmosDbController> logger): ControllerBase
{
    [HttpPost("{cosmosdbId:int?}", Name = "CallCosmosDb")]
    public async Task<IActionResult> CallCosmosDb([FromBody]CosmosSampleRecordModel? model, [FromRoute]int? cosmosdbId = 0)
    {
        try
        {
            var cosmosDbConnection = await cosmosDbConnectionFactory.GetCosmosDbConnection(cosmosdbId.GetValueOrDefault()).ConfigureAwait(false);
            
            Assumes.NotNull(cosmosDbConnection);
            Assumes.NotNull(model);
            
            var result = await cosmosDbConnection.UpsertItemAsync(model);
            return result.StatusCode.IsSuccess()? Ok(): StatusCode((int)result.StatusCode);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, $"Error trying to Inspect CosmosDb: {cosmosdbId}");
        }
        return StatusCode((int)HttpStatusCode.InternalServerError);
    }
}