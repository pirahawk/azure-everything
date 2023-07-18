using Dapr.Actors.Client;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddUserSecrets(Assembly.GetExecutingAssembly(), true);
builder.Configuration.AddEnvironmentVariables();

// Add services to the container.
builder.Services.AddHealthChecks();
builder.Services
    .AddControllers()
    .AddDapr();


// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddTransient<IActorProxyFactory>(serviceProvider =>
{
    var logger = serviceProvider.GetService<ILogger<IActorProxyFactory>>();
    var configurationRoot = serviceProvider.GetService<IConfiguration>();
    // Note: For the Actors Proxy to work, you need to know the URL (mainly the Dapr Sidecar PORT number)
    // of the target Dapr Sidecar that hosts the app that contains the Actors defined within.
    // You must always point to the Dapr sidecar in the url, not the Apps hosted url:port.

    var daprApiSidecarPort = configurationRoot?.GetValue<int?>("Dapr:ApiSidecarPort");
    var daprApiSidecarHostName = configurationRoot?.GetValue<string?>("Dapr:ApiSidecarHostName");
    var daprApiSidecarScheme = configurationRoot?.GetValue<string?>("Dapr:ApiSidecarScheme");

    var daprActorUrl = $"{daprApiSidecarScheme}://{daprApiSidecarHostName}:{daprApiSidecarPort}";


    if (daprApiSidecarPort == null)
    {
        var message = $"IActorProxyFactoryInvocation: Unable to bind to configuration setting: Dapr:ApiSidecarPort";
        logger?.LogError(message);
        throw new ArgumentException(message);
    }

    if (string.IsNullOrWhiteSpace(daprApiSidecarHostName))
    {
        var message = $"IActorProxyFactoryInvocation: Unable to bind to configuration setting: Dapr:ApiSidecarHostName";
        logger?.LogError(message);
        throw new ArgumentException(message);
    }

    if (string.IsNullOrWhiteSpace(daprApiSidecarScheme))
    {
        var message = $"IActorProxyFactoryInvocation: Unable to bind to configuration setting: Dapr:ApiSidecarScheme";
        logger?.LogError(message);
        throw new ArgumentException(message);
    }

    logger?.LogInformation($"IActorProxyFactoryInvocation: Actor proxy URL created for {daprActorUrl}");
    var proxyOptions = new ActorProxyOptions
    {
        HttpEndpoint = daprActorUrl,
    };

    return new ActorProxyFactory(proxyOptions);
});

builder.Services.AddActors(configure =>
{


});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

//app.UseAuthorization();

app.MapControllers();

app.Run();
