using AzContainerAppService.Dapr.Common;
using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace AzContainerAppService.Dapr.PubSub.PublishApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly DaprClient daprClient;
        private readonly ILogger<OrderController> logger;

        public OrderController(DaprClient daprClient, ILogger<OrderController> logger)
        {
            this.daprClient = daprClient;
            this.logger = logger;
        }

        [HttpPost(template: "publish", Name = "OrderPublish")]
        public async Task<IActionResult> PostOrder([FromBody] Order orderToSend)
        {
            // Publish an event/message using Dapr PubSub
            await this.daprClient.PublishEventAsync("orderpubsub", "orders", orderToSend);
            logger.LogInformation("Published data: " + orderToSend.OrderId);
            
            return StatusCode((int)HttpStatusCode.Accepted, orderToSend);
        }
    }
}