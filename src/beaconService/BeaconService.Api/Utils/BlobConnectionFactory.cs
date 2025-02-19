using Azure.Identity;
using Azure.Storage.Blobs;
using BeaconService.Api.Controllers;
using BeaconService.Api.Models;
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

        var azureCredential = new DefaultAzureCredential();

        // Need the following because I am using a user assigned managed identity.
        // Hence I need to expect the client ID to exist as an env var. (see your bicep to ensure this env var is being set)
        // https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential?view=azure-dotnet#examples
        string? userAssignedClientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");

        this.logger.LogInformation($"Environment Variable for AZURE_CLIENT_ID: {userAssignedClientId}");
        if (!string.IsNullOrWhiteSpace(userAssignedClientId))
        {
            this.logger.LogInformation($"Attempting Managed Identity Auth for AZURE_CLIENT_ID: {userAssignedClientId}");
            azureCredential = new DefaultAzureCredential(
                new DefaultAzureCredentialOptions
                {
                    ManagedIdentityClientId = userAssignedClientId
                });
        }

        var blobServiceClient = new BlobServiceClient(
        new Uri(blobConfig.BlobUrl),
        azureCredential);

        var blobContainerClient = blobServiceClient.GetBlobContainerClient(blobConfig.ContainerName);
        return blobContainerClient;
    }
}