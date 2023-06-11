using AzAppConfiguration.Controllers;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;
using Microsoft.Extensions.Options;
using Microsoft.FeatureManagement;

var builder = WebApplication.CreateBuilder(args);


//var appConfigUri = builder.Configuration.GetValue<string>($"{nameof(ApiOptions)}:{nameof(ApiOptions.AppConfigurationUri)}");
var appConfigConnection = builder.Configuration.GetConnectionString("AppConfig");
var test = builder.Environment.EnvironmentName;

if (!string.IsNullOrWhiteSpace(appConfigConnection))
{
    builder.Configuration.AddAzureAppConfiguration(appConfigOptions =>
    {
        var cliCredentials = new AzureCliCredential(); // For this to work, make sure that App Config has a System Identity (or equivalent). See: https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-integrate-azure-managed-service-identity?tabs=core5x&pivots=framework-dotnet
        appConfigOptions
        .Connect(new Uri(appConfigConnection), cliCredentials)
        .ConfigureKeyVault(kv =>
        {
            // What is super interesting, I know that there will be KV secrets in the App Config, I only need to set the KV access credentials, I don't need to know the actual name of the keyvault or need to maintain that configuration
            // By virtue of creating the KeyValut reference (see your deploy scripts, this was all handled by App Config from that point
            kv.SetCredential(cliCredentials);
        })
        // Load configuration values with no label
        .Select(KeyFilter.Any, LabelFilter.Null)
        // Override with any configuration values specific to current hosting env
        .Select(KeyFilter.Any, builder.Environment.EnvironmentName);

        // Load all feature flags with no label
        appConfigOptions.UseFeatureFlags();
    });
}

builder.Services.AddFeatureManagement();

builder.Services.Configure<TestOptions>(builder.Configuration.GetSection(nameof(TestOptions)));

// Add services to the container.
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
