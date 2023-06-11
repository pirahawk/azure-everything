# To run:  .\az-app-configuration\set-secrets.ps1

# Set secret in the KeyVault
$azKeyVault=$(az keyvault list --query "[?(contains(name, 'keyvault'))].name" --output tsv)
az keyvault secret set --vault-name $azKeyVault --name "TestOptions--Secret"  --value "KV Secret" --content-type "string"
$testSecretId=$(az keyvault secret show -n "TestOptions--Secret" --vault-name $azKeyVault --query "id" --output tsv)


# Assign Endpoint secrets to local project
$azAppConfigName=$(az appconfig list --query "[?(contains(name, 'appconfig'))].name" --output tsv)
$azAppConfigEndpoint = $(az appconfig show -n "$azAppConfigName" --query "endpoint")

# I am resetting the keys here through AZ CLI, as BICEP does not support setting labels for some reason
# I am also overriding the content type because otherwise it keeps erroring saying it expects JSON
az appconfig kv set -n $azAppConfigName --content-type text/html --key "TestOptions:Name" --value Foo --yes
az appconfig kv set -n $azAppConfigName --content-type text/html --key "TestOptions:Secret" --value Bar --yes
az appconfig kv set -n $azAppConfigName --content-type text/html --key "TestOptions:Message" --value 'Prod Message' --yes
az appconfig kv set -n $azAppConfigName --content-type text/html --key "TestOptions:Message" --value 'Dev Message' --label Development --yes

# Set a KV secret reference in the APP configuration
# NOTE: What is interesting is if you look at what is generated in the App config AZ portal (go Advanced Edit), 
# then "in theory" you should be able to set this via Bicep.
#
# See how the content type is set to ``"content_type": "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"``
az appconfig kv set-keyvault -n $azAppConfigName --key "TestOptions:Secret" --secret-identifier $testSecretId --yes

Write-Output "App endpoint is $azAppConfigEndpoint"
dotnet user-secrets init -p .\az-app-configuration\AzAppConfiguration\AzAppConfiguration\AzAppConfiguration.csproj
dotnet user-secrets set "ConnectionStrings:AppConfig" "$azAppConfigEndpoint" -p .\az-app-configuration\AzAppConfiguration\AzAppConfiguration\AzAppConfiguration.csproj
