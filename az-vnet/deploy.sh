#! /bin/bash

if [[ ! $1 ]]
then
    echo 'Random Prefix is missing'
else
    randomSuffix=$1
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
echo "executing deployment $azDeploymentName"

az deployment group create -g $azGroupName -n $azDeploymentName --no-wait -f ./az-vnet/bicep/deploy.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId"