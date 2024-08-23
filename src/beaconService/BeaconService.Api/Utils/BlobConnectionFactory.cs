using Azure.Identity;
using Azure.Storage.Blobs;
using BeaconService.Api.Controllers;
using Microsoft;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Utils;

public class BlobConnectionFactory
{
    private readonly IOptions<BeaconConfigurationModel> beaconConfiguration;
    private readonly ILogger<BlobConnectionFactory> logger;

    public BlobConnectionFactory(IOptions<BeaconConfigurationModel> beaconConfiguration, ILogger<BlobConnectionFactory> logger)
    {
        this.beaconConfiguration = beaconConfiguration;
        this.logger = logger;
    }

    public BlobContainerClient GetBlobStoreConnection(int connectionId)
    {
        var blobConfig = beaconConfiguration.Value.BlobStores.ToArray()[connectionId];
        Assumes.NotNull(blobConfig);

        var blobServiceClient = new BlobServiceClient(
        new Uri(blobConfig.BlobUrl),
        new DefaultAzureCredential());

        var blobContainerClient = blobServiceClient.GetBlobContainerClient(blobConfig.ContainerName);
        return blobContainerClient;
    }
}