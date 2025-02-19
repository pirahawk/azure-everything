using System.Net;
using BeaconService.Api.Models;
using BeaconService.Api.Utils;
using Microsoft;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class BlobStoreController(
    IOptions<BeaconConfigurationModel> beaconConfiguration, 
    ILogger<BlobStoreController> logger, 
    BlobConnectionFactory blobConnectionFactory) : ControllerBase
{
    // private readonly IOptions<BeaconConfigurationModel> beaconConfiguration = beaconConfiguration;
    // private readonly ILogger<BlobStoreController> logger = logger;
    // private readonly BlobConnectionFactory blobConnectionFactory = blobConnectionFactory;

    [HttpGet("{blobstoreId:int?}", Name = "CallBlobStore")]
    public async Task<IActionResult> CallBlobStore(int? blobstoreId = 0)
    {
        try
        {
            
            var containerClient = blobConnectionFactory.GetBlobStoreConnection(blobstoreId ?? default);
            Assumes.NotNull(containerClient);

            var exists = await containerClient.ExistsAsync();
            return exists.Value? Ok($"Blob Client: {containerClient.Name} exists on {containerClient.AccountName}") : StatusCode((int)HttpStatusCode.NotFound);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, $"Error trying to Inspect BlobStore: {blobstoreId}");
        }
        return StatusCode((int)HttpStatusCode.InternalServerError);
    }
}