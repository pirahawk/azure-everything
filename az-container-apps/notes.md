

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