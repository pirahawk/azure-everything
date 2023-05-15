# To run:  .\<FOLDER>\deploy.ps1

$random = "[randomGuidSuffix]"
$azGroupName = "az-[group name]-$random"
$azDeploymentName = "deployment-$azGroupName"


if($null -eq $(az group show -n $azGroupName)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\<FOLDER>\bicep\deploy.bicep `
 --parameters `
 resourceGroupName=$azGroupName `
 targetLocation="uksouth"