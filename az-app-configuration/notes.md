# deploy.ps1 script
```
# To run:  .\az-app-configuration\deploy.ps1

$random = "<random-guid>"
$azGroupName = "az-app-configuration-$random"
$azDeploymentName = "deployment-$azGroupName"


if($null -eq $(az group show -n $azGroupName)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

$sid = $(az ad signed-in-user show --query "id").Trim('"')

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-app-configuration\bicep\deploy.bicep `
 --parameters `
 randomSuffix="$random" `
 userPrincipalId="$sid"
```