using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace AzContainerReg.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        private readonly IOptions<AppOptions> options;
        private readonly ILogger<TestController> _logger;

        public TestController(IOptions<AppOptions> options,ILogger<TestController> logger)
        {
            this.options = options;
            _logger = logger;
        }

        [HttpGet(Name = "GetTestConfiguration")]
        public string Get()
        {
            return $"Configured Station name: {options?.Value?.StationName}";
        }
    }
}