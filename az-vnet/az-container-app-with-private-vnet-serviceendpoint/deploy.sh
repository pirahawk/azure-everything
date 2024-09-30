#! /bin/bash

if [[ ! $1 ]]
then
    echo 'Random Suffix is missing'
    exit 1
else
    echo "Random Suffix: $1"
    randomSuffix=$1
fi

if [[ ! $2 ]]
then
    echo 'SSH key path is missing'
    exit 1
else
    echo "SSH key path: $2"
    vmsshkeypath=$2
fi

# Create the SSH key to use (if it does not exist)

vmsshkeypubpath="$vmsshkeypath.pub"
echo "Checking if SSH key exists: $vmsshkeypubpath"

if [ -e "$vmsshkeypubpath" ]; # This is interesting for this if statement: https://stackoverflow.com/questions/638975/how-do-i-tell-if-a-file-does-not-exist-in-bash
then
     echo "SSH key exists: $vmsshkeypubpath"
     vmsshkeypub=$(<"$vmsshkeypubpath")
else
    echo "SSH key does not exist: $vmsshkeypubpath Generating Key"
    ssh-keygen -t rsa -b 4096 -f $vmsshkeypath -N '' # Notice the -N '' That sets an empty passphrase so you don't get prompted
    vmsshkeypub=$(<"$vmsshkeypubpath")
fi

azGroupName="az-vnet-$randomSuffix"
azDeploymentName="deployment-$randomSuffix"
azAvailabilityZone="uksouth"

azGroupFound=$(az group show -n $azGroupName --query 'name' -o tsv)
# echo $azGroupFound

if [[ ! $azGroupFound ]]
then
    echo "Resource Group '$azGroupName' does not exist. Creating group now"
    az group create -l $azAvailabilityZone -n $azGroupName
else 
    echo "Resource Group '$azGroupName' already exists"
fi

azSignedInUserId=$(az ad signed-in-user show --query "id" -o tsv)

echo "Signed In as $azSignedInUserId"



# So I found that I first have to create the VNET by iteself (hence why in its own BICEP with wait on deployment to finish).
# Reason for this, you don't want to re-deploy the VNET + Subnet if it already exists, I found it tends to want to re-create the subnet for some reason.
# Also the VNET provisioning can take some time. If I don't wait for it, the subsequent scripts will fail because they reference the VNET + Subnets etc.
# Hence I want to wait for it all to deploy and put some effor into ensuring it exists before re-deploying again.

vnetName="vnet$randomSuffix"
vnetExistCheck=$(az network vnet show -g $azGroupName -n $vnetName --query "name" -o tsv)
vnetSubnetExistCheck=$(az network vnet show -g $azGroupName -n $vnetName --query "subnets[].name" -o tsv)
shouldDeploySubnet=false

if [[ ! $vnetExistCheck ]]
then
    echo "VNET '$vnetName' does not exist. Will create VNET"
    shouldDeploySubnet=true
else 
    echo "VNET '$vnetName' exists. Will NOT re-create VNET"
fi

 echo "VNET Check outcome is: $shouldDeploySubnet"


if $shouldDeploySubnet
then
    echo "executing deployment $azDeploymentName"
# Notice how we are waiting for VNET deploy to finish. Because the two deployments below will need it to be in place.
    az deployment group create -g $azGroupName -n "vnet-$azDeploymentName" -f ./az-vnet/az-container-app-with-private-vnet-serviceendpoint/bicep/deployvnet.bicep \
    --parameters \
    randomSuffix="$randomSuffix" \
    userPrincipalId="$azSignedInUserId" \
    shouldDeploySubnet=$shouldDeploySubnet
fi

# --no-wait
# Update: Sadly I cannot use the "--no-wait" flag on the deployments below, because the Azure Private DNS zone depends on the two deployments being in place.

az deployment group create -g $azGroupName -n "vm-$azDeploymentName" -f ./az-vnet/az-container-app-with-private-vnet-serviceendpoint/bicep/deployVm.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId" \
 sshPublicKey="$vmsshkeypub"

# need to wait for this as the private DNS Zone depends on the resources created here

# deploy all the service endpoint resources first (will be referenced later)
az deployment group create -g $azGroupName -n "services-$azDeploymentName"  -f ./az-vnet/az-container-app-with-private-vnet-serviceendpoint/bicep/deployServiceEndpointResources.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId"

az deployment group create -g $azGroupName -n "app-$azDeploymentName"  -f ./az-vnet/az-container-app-with-private-vnet-serviceendpoint/bicep/deployContainerApps.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId"



# I now need to resolve the default domain of the Azure Container App. This is because the Private DNS zone needs to contain the same domain so that the A records will translate correctly.
# See this video: https://www.youtube.com/watch?v=ccDzgfVslR0&list=LL&index=1
containerAppDefaultDomain=$(az containerapp env show -g $azGroupName -n "containerappenv$randomSuffix" --query "properties.defaultDomain" -o tsv)
containerAppIp=$(az containerapp env show -g $azGroupName -n "containerappenv$randomSuffix" --query "properties.staticIp" -o tsv)


if [[ ! $containerAppDefaultDomain ]]
then
    echo "Container App Domain could not be found. Skipping Creating DNS zone for container app"
    exit 1
else
    echo "Container App Domain is '$containerAppDefaultDomain' Will create DNS zone for container app"
fi

 # need to wait for this as the private DNS Zone depends on the resources created here
az deployment group create -g $azGroupName -n "dnszone-$azDeploymentName"  -f ./az-vnet/az-container-app-with-private-vnet-serviceendpoint/bicep/deployDns.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId" \
 containerAppDefaultDomain="$containerAppDefaultDomain" \