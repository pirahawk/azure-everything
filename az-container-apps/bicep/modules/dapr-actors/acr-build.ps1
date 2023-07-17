# To run:  .\az-container-apps\acr-build.ps1
param([parameter(mandatory=$true )]$random)

$acrGroupName=$(az group list --query "[?contains(name, 'az-container-apps-$random')].name" --output tsv)
$acrName=$(az acr list -g $acrGroupName --query "[].loginServer" --output tsv)

Write-Output "ACR location is: $acrName"

# To run the build as a one off acr run task
az acr run --registry $acrName https://github.com/pirahawk/azure-everything.git -f .\az-container-apps\bicep\modules\dapr-actors\acr-build-task.yaml --platform linux
