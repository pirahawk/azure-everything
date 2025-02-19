using BeaconService.Api.Controllers;
using BeaconService.Api.Models;
using Microsoft;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;

namespace BeaconService.Api.Utils;

public class CosmosDbConnectionFactory(
    IOptions<BeaconConfigurationModel> beaconConfiguration,
    ILogger<CosmosDbConnectionFactory> logger,
    AzureCredentialFactory azureCredentialFactory)
{
    public async Task<Container?> GetCosmosDbConnection(int connectionId)
    {
        var cosmosDbConfigurationModel = beaconConfiguration.Value.CosmosDbs.ToArray()[connectionId];
        Assumes.NotNull(cosmosDbConfigurationModel);
        Assumes.NotNullOrEmpty(cosmosDbConfigurationModel.PartitionKeyPath);

        if (cosmosDbConfigurationModel.IsEmulator)
        {
            return await BuildEmulatedCosmosContainerConnection(cosmosDbConfigurationModel);
        }
        
        logger.LogInformation($"Attempting to create Cosmos DB connection for {cosmosDbConfigurationModel.Account} - {cosmosDbConfigurationModel.Database} - {cosmosDbConfigurationModel.Container}");
        return await BuildCosmosContainerConnection(cosmosDbConfigurationModel);
    }

    private async Task<Container?> BuildCosmosContainerConnection(CosmosDbConfigurationModel cosmosDbConfigurationModel)
    {
        var azureCredential = azureCredentialFactory.BuildAzureCredential();
        
        var cosmosClient = new CosmosClient(
            accountEndpoint: cosmosDbConfigurationModel.Account,
            tokenCredential: azureCredential
        );
        
        Database database = cosmosClient.GetDatabase(cosmosDbConfigurationModel.Database);
        Container container = database.GetContainer(cosmosDbConfigurationModel.Container);

        return await Task.FromResult(container).ConfigureAwait(false);
    }

    private async Task<Container?> BuildEmulatedCosmosContainerConnection(CosmosDbConfigurationModel cosmosDbConfigurationModel)
    {
        logger.LogInformation($"Attempting to create Emulated Cosmos DB connection for {cosmosDbConfigurationModel.Account} - {cosmosDbConfigurationModel.Database} - {cosmosDbConfigurationModel.Container}");
        Assumes.NotNull(cosmosDbConfigurationModel.CosmosDbEmulatorAuthKey);

        CosmosClientOptions options = new()
        {
            HttpClientFactory = () => new HttpClient(new HttpClientHandler()
            {
                ServerCertificateCustomValidationCallback =
                    HttpClientHandler.DangerousAcceptAnyServerCertificateValidator
            }),
            ConnectionMode = ConnectionMode.Gateway,
        };

        CosmosClient client = new(
            accountEndpoint: cosmosDbConfigurationModel.Account,
            authKeyOrResourceToken: cosmosDbConfigurationModel.CosmosDbEmulatorAuthKey,
            options);

        Database mydb = await client.CreateDatabaseIfNotExistsAsync(
            id: cosmosDbConfigurationModel.Database,
            throughput: 400
        );

        Container myContainer = await mydb.CreateContainerIfNotExistsAsync(
            id: cosmosDbConfigurationModel.Container,
            partitionKeyPath: cosmosDbConfigurationModel.PartitionKeyPath
        );

        return myContainer;
    }
}