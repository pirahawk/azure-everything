using System.Text.Json.Serialization;
using Newtonsoft.Json;

namespace BeaconService.Api.Models;

public record CosmosSampleRecordModel
{
    [JsonPropertyName("id")]
    [JsonProperty("id")]
    public required string Id { get; set; }
    
    [JsonPropertyName("name")]
    [JsonProperty("name")]
    public required string Name { get; set; }
}