using AzContainerAppService.Dapr.Common;
using Dapr;
using Dapr.Client;
using Microsoft.AspNetCore.Mvc;

namespace AzContainerAppService.Dapr.PubSub.SubscribeApi.Controllers
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

        [HttpPost(template: "process", Name = "processOrders")]
        [Topic("orderpubsub", "orders")]
        public async Task<IActionResult> PostOrder([FromBody] Order order)
        {
            logger.LogInformation("Order Recived data: " + order.OrderId);
            return await Task.FromResult(Ok(order));
        }
    }
}