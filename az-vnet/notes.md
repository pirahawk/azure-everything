Once deployed

```
ssh -i ./.ssh/<ssh private key> testuser@<vm ip address>

curl -X 'GET' 'https://beacontwo<suffix>.<whatever>.uksouth.azurecontainerapps.io/configuration' -H 'accept: */*'
curl -X 'GET' 'https://beacontwo<suffix>.<whatever>.uksouth.azurecontainerapps.io/Endpoints/0' -H 'accept: */*'
curl -X 'GET' 'https://beacontwo<suffix>.<whatever>.uksouth.azurecontainerapps.io/BlobStore/0' -H 'accept: */*'

```
https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.app/container-app-vnet-internal-environment


https://learn.microsoft.com/en-us/azure/container-apps/ingress-how-to?pivots=azure-cli


https://learn.microsoft.com/en-us/azure/container-apps/waf-app-gateway?tabs=default-domain



Service Endpoints tutorial here

for list of services that can have service endpoints:
https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview

for general tutorial of how to service endpoints and private endpoints are setup in bicep see:
https://bhabalajinkya.medium.com/azure-bicep-private-communication-between-azure-resources-f4a17c171cfb

Also see:
https://learn.microsoft.com/en-us/azure/private-link/create-private-endpoint-bicep?tabs=CLI
https://learn.microsoft.com/en-us/azure/private-link/create-private-link-service-bicep?tabs=CLI

private link vs service endpoints
https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/service-endpoints-vs-private-endpoints/ba-p/3962134