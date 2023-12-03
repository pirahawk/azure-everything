# To run the Dapr Az container Apps locally


**MAKE SURE YOUR --app-port VALUES MATCH THE ONES SET IN 'launchSettings.json' for each project**

AzContainerAppService.Dapr.PubSub.SubscribeApi.csproj
```
dapr run --app-id csharp-subscriber --dapr-http-port 64441 --app-port 5027 --components-path ".\az-container-apps\local-az-dapr-components" -- dotnet run --project .\az-container-apps\AzContainerAppService\AzContainerAppService.Dapr.PubSub.SubscribeApi\AzContainerAppService.Dapr.PubSub.SubscribeApi.csproj
```


AzContainerAppService.Dapr.PubSub.PublishApi.csproj
```
dapr run --app-id csharp-publisher --dapr-http-port 65295 --app-port 5023 --components-path ".\az-container-apps\local-az-dapr-components" -- dotnet run --project .\az-container-apps\AzContainerAppService\AzContainerAppService.Dapr.PubSub.PublishApi\AzContainerAppService.Dapr.PubSub.PublishApi.csproj
```

AzContainerAppService.Dapr.Actors.ActorClientApi.csproj
```
dapr run --app-id dapr-actor-client-api --dapr-http-port 64441 --app-port 5080 --components-path ".\az-container-apps\local-az-dapr-components" -- dotnet run --project .\az-container-apps\AzContainerAppService\AzContainerAppService.Dapr.Actors.ActorClientApi\AzContainerAppService.Dapr.Actors.ActorClientApi.csproj
```

AzContainerAppService.Dapr.Actors.ActorServerApi.csproj
```
dapr run --app-id dapr-actor-api --dapr-http-port 65295 --app-port 5049 --components-path ".\az-container-apps\local-az-dapr-components" -- dotnet run --project .\az-container-apps\AzContainerAppService\AzContainerAppService.Dapr.Actors.ActorServerApi\AzContainerAppService.Dapr.Actors.ActorServerApi.csproj
```


See this

https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml


# Queries Used in the logAnalyticsWorkspace

```

ContainerAppConsoleLogs_CL
| order by _timestamp_d asc
| where ContainerName_s startswith "daprd"
| project  Log_s


ContainerAppConsoleLogs_CL
| where ContainerName_s == 'dapractorclient'
| order by _timestamp_d asc
| project  Log_s


ContainerAppConsoleLogs_CL
| where ContainerName_s == 'dapractorserver'
| order by _timestamp_d asc
| project  Log_s


ContainerAppSystemLogs_CL
| where ContainerAppName_s startswith "dapractorclient"
| order by _timestamp_d asc
| project  Log_s


AppRequests 
| where Name != "GET /health" and Name != "GET /healthz"
```

# deploy.ps1 script
```
# To run:  .\az-container-apps\deploy.ps1

$random = "<random-guid>"
$azGroupName = "az-container-apps-$random"
$azDeploymentName = "deployment-$azGroupName"
$sid = $(az ad signed-in-user show --query "id").Trim('"')


if($null -eq $(az group show -n $azGroupName)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}



# Deploy Simple NO RBAC
#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\no-rbac-simple\deployContainerAppSimpleNoRbac.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"




# Deploy with RBAC

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\with-rbac\deployContainerRegistry.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"

#  .\az-container-apps\acr-build.ps1

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\with-rbac\deployContainerApp.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"








# Deploy Client Server with RBAC

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\with-rbac-client-server\deployContainerRegistry.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"

# .\az-container-apps\acr-build.ps1

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\with-rbac-client-server\deployContainerApp.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"










# Deploy Dapr Pub Sub

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\dapr-pubsub\deployContainerRegistry.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"


#  .\az-container-apps\bicep\modules\dapr-pubsub\acr-build.ps1 -random $random

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\dapr-pubsub\deployContainerApp.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"






# Deploy Dapr Actors

#  az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\dapr-actors\deployContainerRegistry.bicep `
#  --parameters `
#  randomSuffix="$random" `
#  userPrincipalId="$sid"

# .\az-container-apps\bicep\modules\dapr-actors\acr-build.ps1 -random $random

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-container-apps\bicep\modules\dapr-actors\deployContainerApp.bicep `
 --parameters `
 randomSuffix="$random" `
 userPrincipalId="$sid"
```