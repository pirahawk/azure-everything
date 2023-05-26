# To run:  .\az-containerregistry\acr-build.ps1

$acrGroupName=$(az group list --query "[?contains(name, 'az-containerregistry')].name" --output tsv)
$acrName=$(az acr list -g $acrGroupName --query "[].loginServer" --output tsv)

Write-Output "ACR location is: $acrName"

# az acr login -n $acrName --expose-token

# NOTE: I needed to set the context to the level of the Solution directory "AzContainerReg" not the Project because the dockerfile assumes it is at that level when it copies the .csproj file
#az acr build --image azcontainerreg/myapi:latest --registry $acrName --file .\az-containerregistry\AzContainerReg\AzContainerReg\Dockerfile .\az-containerregistry\AzContainerReg\

az acr run --registry $acrName -f .\az-containerregistry\acr-build-task.yaml https://github.com/pirahawk/azure-everything.git