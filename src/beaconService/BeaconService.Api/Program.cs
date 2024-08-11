using System.Reflection;
using BeaconService.Api.Controllers;
using Microsoft;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddUserSecrets(Assembly.GetExecutingAssembly(), true);
builder.Configuration.AddEnvironmentVariables();

// Add services to the container.

builder.Services.AddHealthChecks();
builder.Services.AddControllers();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddOptions<BeaconConfigurationModel>().BindConfiguration("");
BuildClientServices();



var app = builder.Build();

// Configure the HTTP request pipeline.
// if (app.Environment.IsDevelopment())
// {
app.UseSwagger();
app.UseSwaggerUI();
//}


app.MapControllers();
app.MapHealthChecks("/health");

app.Run();


void BuildClientServices()
{
    var model = builder.Configuration.Get<BeaconConfigurationModel>();
    var index = 0;
    
    Assumes.NotNull(model);
    
    foreach (var endpoint in model.ApiEndPoints)
    {
        Console.WriteLine(endpoint);
        builder.Services.AddHttpClient($"{BeaconConfigurationModel.ApiHttpClientPrefix}{index++}", httpClient =>{
            httpClient.BaseAddress = new Uri(endpoint);
        });
    }
}