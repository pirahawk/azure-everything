#! /bin/bash

if [[ ! $1 ]]
then
    echo 'Random Suffix is missing'
    exit 1
else
    randomSuffix=$1
fi

azGroupName="az-[GROUP NAME HERE]-$randomSuffix"
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

az deployment group create -g $azGroupName -n $azDeploymentName --no-wait -f ./[FOLDER]/bicep/blob.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId"