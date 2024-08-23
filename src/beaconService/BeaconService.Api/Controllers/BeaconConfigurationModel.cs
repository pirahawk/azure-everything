namespace BeaconService.Api.Controllers;

public record BeaconConfigurationModel
{
    public const string ApiHttpClientPrefix = "ApiClient";

    public string? ServiceName { get; set; }
    public IEnumerable<string> ApiEndPoints { get; set; } = Enumerable.Empty<string>();
    public IEnumerable<BlobStoreConfigurationModel> BlobStores { get; set; } = Enumerable.Empty<BlobStoreConfigurationModel>();
}

public record BlobStoreConfigurationModel{
    public string? Name { get; set; }
    public required string BlobUrl { get; set; }
    public required string ContainerName { get; set; }
}
