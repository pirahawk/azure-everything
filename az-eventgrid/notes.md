# deploy.ps1 script
```
# To run:  .\az-eventgrid\deploy.ps1

$random = "<random-guid>"
$azGroupName = "az-eventgrid-$random"
$azDeploymentName = "deployment-$azGroupName"


if($null -eq $(az group show -n $azGroupName)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

#will need Event Grid registered
az provider register -n 'Microsoft.EventGrid'

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-eventgrid\bicep\deploy.bicep `
 --parameters `
 resourceGroupName=$azGroupName `
 targetLocation="uksouth" `
 blobStorageName="storage$random" `
 appServicePlanName="azAsp$random" `
 webAppServiceName="azAsp$random" `
 eventGridSystemTopicName="eventGridSystemTopic$random"
```