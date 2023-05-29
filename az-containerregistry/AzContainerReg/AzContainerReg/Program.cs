using AzContainerReg;
using Azure.Identity;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.json")
    .AddUserSecrets(Assembly.GetExecutingAssembly(), true)
    .AddEnvironmentVariables();

var keyVaultUri = builder.Configuration.GetValue<string>($"{nameof(AppOptions)}:{nameof(AppOptions.KeyVaultUri)}");

if (!string.IsNullOrEmpty(keyVaultUri))
{
    builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUri), new DefaultAzureCredential());
}

// Add services to the container.
builder.Services.Configure<AppOptions>(builder.Configuration.GetSection(nameof(AppOptions)));
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
// if (app.Environment.IsDevelopment())
// {
    app.UseSwagger();
    app.UseSwaggerUI();
// }

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
