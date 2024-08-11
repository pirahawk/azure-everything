# To Publish

```bash
dotnet publish ./src/beaconService/BeaconService.Api/BeaconService.Api.csproj -c Debug -o ./pub/beaconService/

dotnet pub/beaconService/BeaconService.Api.dll
```


```bash
docker build -t beaconservice:latest -f ./src/beaconService/dockerfile .

docker run --rm -d -p 7285:443 -p 5285:80 -e ASPNETCORE_URLS="http://+" beaconservice:latest -n mybeaconservice
```

