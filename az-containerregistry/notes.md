```
// Run build yourself
docker build -t azcontainerreg:latest -f .\az-containerregistry\AzContainerReg\AzContainerReg\Dockerfile .\az-containerregistry\AzContainerReg\
docker run --name testContainerReg -it  -p 32769:80  --env=ASPNETCORE_ENVIRONMENT=Development --env='ASPNETCORE_URLS=http://+:80'  azcontainerreg:latest
```


* Note that you can use ACR build tasks
https://learn.microsoft.com/en-gb/azure/container-registry/container-registry-tasks-reference-yaml

https://learn.microsoft.com/en-gb/azure/container-registry/container-registry-tutorial-build-task

* For build task properties see
https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries?pivots=deployment-language-bicep#registryproperties

* For samples
https://github.com/Azure-Samples/acr-tasks


# ACR Run Tasks
Note that you ensure that any paths to the dockerfile or the build context directory in the .yaml file match the directory seperator of the chosen platform (linux/windows)