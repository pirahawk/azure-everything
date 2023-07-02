#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["AzContainerAppService.Dapr.PubSub.PublishApi/AzContainerAppService.Dapr.PubSub.PublishApi.csproj", "AzContainerAppService.Dapr.PubSub.PublishApi/"]
RUN dotnet restore "AzContainerAppService.Dapr.PubSub.PublishApi/AzContainerAppService.Dapr.PubSub.PublishApi.csproj"
COPY . .
WORKDIR "/src/AzContainerAppService.Dapr.PubSub.PublishApi"
RUN dotnet build "AzContainerAppService.Dapr.PubSub.PublishApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AzContainerAppService.Dapr.PubSub.PublishApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AzContainerAppService.Dapr.PubSub.PublishApi.dll"]