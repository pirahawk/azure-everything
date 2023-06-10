using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace AzAppConfiguration.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;
        private readonly IOptions<TestOptions> options;

        public TestController(ILogger<TestController> logger, IOptions<TestOptions> options)
        {
            _logger = logger;
            this.options = options;
        }

        [HttpGet()]
        public IActionResult GetConfig()
        {
            return this.Ok(options.Value);
        }
    }

    public class TestOptions
    {
        public string? Name { get; set; }
        public string? Secret { get; set; }
    }
}