using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace AzContainerAppService.ClientApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly ILogger<OrderController> logger;
        private readonly IHttpClientFactory httpClientFactory;

        public OrderController(ILogger<OrderController> logger, IHttpClientFactory httpClientFactory)
        {
            this.logger = logger;
            this.httpClientFactory = httpClientFactory;
        }

        [HttpGet(Name = "TestOrder")]
        public async Task<IActionResult> Get()
        {
            var client = this.httpClientFactory.CreateClient("ServerClient");

            var result = await client.GetAsync("order").ConfigureAwait(false);

            logger.LogInformation($"Http Response from ServerClient {result.StatusCode}");

            if (!result.IsSuccessStatusCode)
            {
                return StatusCode((int)result.StatusCode);
            }

            var order = await result.Content.ReadFromJsonAsync<Order>().ConfigureAwait(false);
            return Ok(order);
        }
    }

    public record Order
    {
        public int OrderId { get; set; }
        public string ItemName { get; set; }
    }

    public record ServerApiOptions
    {
        public string Host { get; set; }
        public string Scheme { get; set; }
    }
}