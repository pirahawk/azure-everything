using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Microsoft.FeatureManagement;

namespace AzAppConfiguration.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;
        private readonly IOptions<TestOptions> options;
        private readonly IFeatureManager featureManager;

        public TestController(
            ILogger<TestController> logger, 
            IOptions<TestOptions> options,
            IFeatureManager featureManager
            )
        {
            _logger = logger;
            this.options = options;
            this.featureManager = featureManager;
        }

        [HttpGet()]
        public IActionResult GetConfig()
        {
            return this.Ok(options.Value);
        }

        [HttpGet("feature", Name = "FeatureTest")]
        public async Task<IActionResult> FeatureTest()
        {
            var isEnabled = await featureManager.IsEnabledAsync("MyTestFeature");
            return this.Ok($"MyTestFeature is {isEnabled}");
        }
    }

    public class TestOptions
    {
        public string? Name { get; set; }
        public string? Secret { get; set; }
        public string? Message { get; set; }
    }
}