# SSH keygen

https://www.ssh.com/academy/ssh/keygen
https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed
https://learn.microsoft.com/en-us/azure/virtual-machines/ssh-keys-azure-cli
https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-bicep?tabs=CLI#review-the-bicep-file

https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-complete
https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli#create-an-ssh-key-pair
https://www.davidc.net/sites/default/subnets/subnets.html


## Step 1 - Generate the SSH key on Windows

You will need to do this from the OS where you are running the bicep as you will need to provision and upload the ssh key PK to your VM.
```
ssh-keygen -t rsa -b 4096 -f C:\Users\<YOUR USERNAME>\Documents\projects\.ssh\id_rsa_mytest
```

## Step 2 - SSH to the VM (from WSL or linux etc once the VM has been provisioned)
**Note:** When you ssh to the VM, it expects that the key has the following perms:
```
mv /mnt/c/<your-private-key> ~/.ssh/

chmod 400 ~/.ssh/<your-private-key>

ssh -i ~/.ssh/<your-private-key> <your-user-name>@<your-public-ip-address>
```
See: https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-permissions-too-open

In order for this to work, **DO NOT** try and be clever and direct link the `/mnt/c/sshkeyfolder` to the `~/.ssh/` folder in WSL. This will not work, just copy it from the mount point and change the permissions.


# Bicep
```
# To run:  .\az-vm\deploy.ps1

$random = "<random-guid>"
$azGroupName = "az-vm-$random"
$azDeploymentName = "deployment-$azGroupName"
$sid = $(az ad signed-in-user show --query "id" -o tsv)


if($null -eq $(az group show -n $azGroupName --query "name" -o tsv)){
    Write-Output "Group $azGroupName does not exist"
    az group create -l 'uksouth' -n $azGroupName    
}else {
    Write-Output "Group $azGroupName exists. Deploying: $azDeploymentName"
}

$vnetName = $(az network vnet list -g $azGroupName --query "[].{name:name}" -o tsv)
$shouldDeploySubnet=$true

if(-not([string]::IsNullOrWhiteSpace($vnetName))){
    
    $subnetId=$(az network vnet subnet list -g $azGroupName --vnet-name $vnetName --query "[].{id:id}" -o tsv)
    
    if(-not([string]::IsNullOrWhiteSpace($subnetId))){
        $shouldDeploySubnet=$false
        Write-Output "Subnet exists. Will Not redeploy: $subnetId"
    }
}

# Deploy an ssh key if it does not exist. I am not sure if I can do this via bicep tbh as were uploading an existing key to azure so just using CLI to do it for now.
# https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/sshpublickeys?pivots=deployment-language-bicep
# NOTE: ASSUMING THAT THE SSH KEY EXITS HERE!! IF NOT CREATE IT (see notes above)
$localSShPubKeyPath = "<your-local-path-to-ssh-folder>\.ssh\id_rsa_mytest.pub"
$sshKeyName = "myvmsshkey$random"
$existKeyId = $(az sshkey show --resource-group $azGroupName --name $sshKeyName --query "id" -o tsv)

if($null -eq $existKeyId){
    Write-Output "SSH key does not exist, creating ssk key : $sshKeyName"
    az sshkey create --location "uksouth" --resource-group "$azGroupName" --name "$sshKeyName" --public-key "@$localSShPubKeyPath"
}else{
    Write-Output "SSH key exists: $sshKeyName"
}

$vmName = "<vm-name>"
$vmUserName = "<vm-user-name>"

 az deployment group create -g $azGroupName -n $azDeploymentName -f .\az-vm\bicep\deploy.bicep --no-wait `
 --parameters `
 randomSuffix="$random" `
 userPrincipalId="$sid" `
 shouldDeploySubnet="$shouldDeploySubnet" `
 vmName="$vmName" `
 vmUserName="$vmUserName" `
 sshKeyName="$sshKeyName"
```
