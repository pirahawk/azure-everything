# To run:  .\az-containerregistry\acr-build.ps1

$acrGroupName=$(az group list --query "[?contains(name, 'az-containerregistry')].name" --output tsv)
$acrName=$(az acr list -g $acrGroupName --query "[].loginServer" --output tsv)

Write-Output "ACR location is: $acrName"

# az acr login -n $acrName --expose-token

# To run a one off manual build direct to the ACR
# NOTE: I needed to set the context to the level of the Solution directory "AzContainerReg" not the Project because the dockerfile assumes it is at that level when it copies the .csproj file
#az acr build --image azcontainerreg/myapi:latest --registry $acrName --file .\az-containerregistry\AzContainerReg\AzContainerReg\Dockerfile .\az-containerregistry\AzContainerReg\

# To run the build as a one off acr run task
#az acr run --registry $acrName https://github.com/pirahawk/azure-everything.git -f .\az-containerregistry\acr-build-task.yaml --platform linux


# To run the build as a dedicated acr task on each commit
az acr task create `
    --registry $acrName `
    --name myacrbuildtask `
    --context https://github.com/pirahawk/azure-everything.git#main `
    --file .\az-containerregistry\acr-build-task.yaml `
    --platform linux `
    --commit-trigger-enabled true `
    --auth-mode None `
    --git-access-token 000000000000000000000000000000000