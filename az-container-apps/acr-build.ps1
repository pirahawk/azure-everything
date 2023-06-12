# To run:  .\az-container-apps\acr-build.ps1

$acrGroupName=$(az group list --query "[?contains(name, 'az-container-apps')].name" --output tsv)
$acrName=$(az acr list -g $acrGroupName --query "[].loginServer" --output tsv)

Write-Output "ACR location is: $acrName"

# To run a one off manual build direct to the ACR
# NOTE: I needed to set the context to the level of the Solution directory "AzContainerReg" not the Project because the dockerfile assumes it is at that level when it copies the .csproj file
#az acr build --image azcontainerreg/myapi:latest --registry $acrName --file .\az-containerregistry\AzContainerReg\AzContainerReg\Dockerfile .\az-containerregistry\AzContainerReg\



# To run the build as a one off acr run task
az acr run --registry $acrName https://github.com/pirahawk/azure-everything.git -f .\az-container-apps\acr-build-task.yaml --platform linux



