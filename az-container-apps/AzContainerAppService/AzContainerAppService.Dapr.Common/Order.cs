using System.Text.Json.Serialization;

namespace AzContainerAppService.Dapr.Common
{
    public record Order([property: JsonPropertyName("orderId")] int OrderId);
}