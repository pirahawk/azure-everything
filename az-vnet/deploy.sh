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
echo "executing deployment $azDeploymentName"


az deployment group create -g $azGroupName -n $azDeploymentName --no-wait -f ./az-vnet/bicep/deploy.bicep \
 --parameters \
 randomSuffix="$randomSuffix" \
 userPrincipalId="$azSignedInUserId" \
 sshPublicKey="$vmsshkeypub"