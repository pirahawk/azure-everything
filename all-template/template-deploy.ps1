# To run:  .\<FOLDER>\deploy.ps1

$random = "[randomGuidSuffix]"
$azGroupName = "az-[group name]-$random"
$azDeploymentName = "deployment-$azGroupName"
#$sid = $(az ad signed-in-user show --query "id").Trim('"')
$sid = $(az ad signed-in-user show --query "id" -o tsv)


if($null -eq $(az group show -n $azGroupName --query "name" -o tsv)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\<FOLDER>\bicep\deploy.bicep `
 --parameters `
 randomSuffix="$random" `
 userPrincipalId="$sid"