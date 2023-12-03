```
// Run build yourself
docker build -t azcontainerreg:latest -f .\az-containerregistry\AzContainerReg\AzContainerReg\Dockerfile .\az-containerregistry\AzContainerReg\
docker run --name testContainerReg -it  -p 32769:80  --env=ASPNETCORE_ENVIRONMENT=Development --env='ASPNETCORE_URLS=http://+:80'  azcontainerreg:latest
```


* Note that you can use ACR build tasks
https://learn.microsoft.com/en-gb/azure/container-registry/container-registry-tasks-reference-yaml

https://learn.microsoft.com/en-gb/azure/container-registry/container-registry-tutorial-build-task

* For build task properties see
https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries?pivots=deployment-language-bicep#registryproperties

* For samples
https://github.com/Azure-Samples/acr-tasks


# ACR Run Tasks
Note that you ensure that any paths to the dockerfile or the build context directory in the .yaml file match the directory seperator of the chosen platform (linux/windows)

# deploy.ps1 script
```
# To run:  .\az-containerregistry\deploy.ps1

$random = "<random-guid>"
$deploymentName="az-containerregistry"
$azGroupName = "$deploymentName-$random"
$azDeploymentName = "deployment-$azGroupName"


if($null -eq $(az group show -n $azGroupName)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

$sid = $(az ad signed-in-user show --query "id").Trim('"')

az deployment group create -g $azGroupName -n $azDeploymentName -f ".\$deploymentName\bicep\deploy.bicep" `
--parameters `
randomSuffix="$random" `
userPrincipalId="$sid"
```