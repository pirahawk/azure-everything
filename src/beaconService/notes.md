# To Publish

```bash
dotnet publish ./src/beaconService/BeaconService.Api/BeaconService.Api.csproj -c Debug -o ./pub/beaconService/

dotnet pub/beaconService/BeaconService.Api.dll
```


```bash
docker build -t beaconservice:latest -f ./src/beaconService/dockerfile .

docker run --rm -d -p 7285:443 -p 5285:80 -e ASPNETCORE_URLS="http://+" beaconservice:latest -n mybeaconservice
```

```dotnetcli
dotnet user-secrets set "ApiEndPoints:0" "http://localhost:5000"


dotnet user-secrets set "BlobStores:0:Name" ""
```


Once the VNET deployment is created:

To ssh
```
chmod 400 ./.ssh/id_rsa_aztestvmkey   // Note: might need to do this if not already done through bash script i wrote

ssh -i ./.ssh/id_rsa_aztestvmkey testuser@<whatever public IP is provisioned>
```



To CURL to the beacon service do so via:
```bash
curl -X 'GET' 'https://beaconservice<suffix>.<whatever  is assigned via deployment>.uksouth.azurecontainerapps.io/configuration' -H 'accept: */*'
```

To ensure that the domain can be resolved use
```bash
nslookup beaconservice<suffix>.<whatever  is assigned via deployment>.uksouth.azurecontainerapps.io
```


Cosmos DB emulator

Assuming using the emulator and have taken setup and run notes from [here](https://learn.microsoft.com/en-us/azure/cosmos-db/emulator-linux#docker-commands)



