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

    az deployment group create -g $azGroupName -n "vnet-$azDeploymentName" -f ./az-vnet/bicep/deployvnet.bicep \
    --parameters \
    randomSuffix="$randomSuffix" \
    userPrincipalId="$azSignedInUserId" \
    shouldDeploySubnet=$shouldDeploySubnet
fi





# az deployment group create -g $azGroupName -n "vm-$azDeploymentName" --no-wait -f ./az-vnet/bicep/deployVm.bicep \
#  --parameters \
#  randomSuffix="$randomSuffix" \
#  userPrincipalId="$azSignedInUserId" \
#  sshPublicKey="$vmsshkeypub"


# az deployment group create -g $azGroupName -n "app-$azDeploymentName" --no-wait -f ./az-vnet/bicep/deployContainerApps.bicep \
#  --parameters \
#  randomSuffix="$randomSuffix" \
#  userPrincipalId="$azSignedInUserId" \
#  sshPublicKey="$vmsshkeypub"