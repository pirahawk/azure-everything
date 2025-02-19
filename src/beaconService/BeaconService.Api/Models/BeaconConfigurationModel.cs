namespace BeaconService.Api.Models;

public record BeaconConfigurationModel
{
    public const string ApiHttpClientPrefix = "ApiClient";

    public string? ServiceName { get; set; }
    public IEnumerable<string> ApiEndPoints { get; set; } = Enumerable.Empty<string>();
    public IEnumerable<BlobStoreConfigurationModel> BlobStores { get; set; } = Enumerable.Empty<BlobStoreConfigurationModel>();
    public IEnumerable<CosmosDbConfigurationModel> CosmosDbs { get; set; } = Enumerable.Empty<CosmosDbConfigurationModel>();
}

public record BlobStoreConfigurationModel{
    public string? Name { get; set; }
    public required string BlobUrl { get; set; }
    public required string ContainerName { get; set; }
}

public record CosmosDbConfigurationModel
{
    public required string Account { get; set; }
    public required string Database { get; set; }
    public required string Container { get; set; }
    public string? CosmosDbEmulatorAuthKey { get; set; }
    public required string PartitionKeyPath { get; set; }
    public bool IsEmulator { get; set; }
}
