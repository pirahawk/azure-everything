using AzContainerAppService.ClientApi.Controllers;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();

// Add services to the container.
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddHealthChecks();

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.Configure<ServerApiOptions>(builder.Configuration.GetSection(nameof(ServerApiOptions)));

builder.Services.AddHttpClient("ServerClient", (serviceProvider, httpClient) => {
    var logger = serviceProvider.GetService<ILogger<IHttpClientBuilder>>();
    var serverOptions = serviceProvider.GetService<IOptions<ServerApiOptions>>();

    if (serverOptions == null || string.IsNullOrWhiteSpace(serverOptions?.Value.Scheme) || string.IsNullOrWhiteSpace(serverOptions?.Value.Host))
    {
        throw new ArgumentNullException(nameof(ServerApiOptions));
    }

    logger?.LogInformation(message: $"{nameof(ServerApiOptions)}: {serverOptions?.Value.Scheme} - {serverOptions?.Value.Host}");
    var clientUrl = $"{serverOptions?.Value.Scheme}://{serverOptions?.Value.Host}";

    httpClient.BaseAddress = new Uri(clientUrl);
    httpClient.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
});

var app = builder.Build();


app.UseSwagger();
app.UseSwaggerUI();


//app.UseHttpsRedirection();

//app.UseAuthorization();

app.MapHealthChecks("/health");
app.MapControllers();

app.Run();



