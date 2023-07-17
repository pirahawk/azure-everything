using AzContainerAppService.Dapr.Common;
using Dapr.Actors;
using Dapr.Actors.Client;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace AzContainerAppService.Dapr.Actors.ActorClientApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly ILogger<OrderController> logger;
        private readonly IActorProxyFactory actorProxyFactory;

        public OrderController(ILogger<OrderController> logger, IActorProxyFactory actorProxyFactory)
        {
            this.logger = logger;
            this.actorProxyFactory = actorProxyFactory;
        }

        [HttpPost(template: "publish", Name = "OrderPublish")]
        public async Task<IActionResult> PostOrder([FromBody] OrderDataState orderToSend)
        {
            var actorType = nameof(OrderActor);
            var actorId = new ActorId($"{orderToSend.Id}");
            var proxy = this.actorProxyFactory.CreateActorProxy<IOrderActor>(actorId, actorType);
            var response = await proxy.SaveStateAsync(orderToSend);
            return StatusCode((int)HttpStatusCode.Accepted, response);

        }
    }
}