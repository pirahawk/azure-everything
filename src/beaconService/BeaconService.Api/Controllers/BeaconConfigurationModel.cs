namespace BeaconService.Api.Controllers;

public record BeaconConfigurationModel
{
    public const string ApiHttpClientPrefix = "ApiClient";

    public string? ServiceName { get; set; }
    public IEnumerable<string> ApiEndPoints { get; set; } = Enumerable.Empty<string>();
}
