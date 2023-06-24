using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace AzContainerAppService.ServerApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly ILogger<OrderController> logger;
        private readonly IOptions<ApiOptions> options;

        public OrderController(ILogger<OrderController> logger, IOptions<ApiOptions> options)
        {
            this.logger = logger;
            this.options = options;
        }

        [HttpGet(Name = "TestOrder")]
        public IActionResult Get()
        {
            logger.LogInformation($"New Order Request");
            var itemName = this.options.Value.ItemName;
            var order = new Order(1, itemName);
            return Ok(order);
        }
    }

    public record Order(int OrderId, string ItemName)
    {

    }

    public record ApiOptions
    {
        public string ItemName { get; set; } = "DefaultItem";
    }
}