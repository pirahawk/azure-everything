# To run:  .\az-app-configuration\set-secrets.ps1

# Assign Endpoint secrets to local project
$azAppConfigName=$(az appconfig list --query "[?(contains(name, 'appconfig'))].name" --output tsv)
$azAppConfigEndpoint = $(az appconfig show -n "$azAppConfigName" --query "endpoint")

Write-Output "App endpoint is $azAppConfigEndpoint"
dotnet user-secrets init -p .\az-app-configuration\AzAppConfiguration\AzAppConfiguration\AzAppConfiguration.csproj
dotnet user-secrets set "ConnectionStrings:AppConfig" "$azAppConfigEndpoint" -p .\az-app-configuration\AzAppConfiguration\AzAppConfiguration\AzAppConfiguration.csproj
