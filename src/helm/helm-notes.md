# Helm Chart Commands

## Chart: testdeploy

Install the test helm chart like so:

```
helm upgrade --debug --dry-run -f ./src/helm/testdeploy/values.yaml my-test-deploy ./src/helm/testdeploy -i -n my-test-deploy --reset-values
```


## Chart: beacon-with-db

Install the test helm chart like so:

```
helm upgrade -f ./src/helm/beacon-with-db/values.yaml my-test-deploy ./src/helm/beacon-with-db -i -n my-test-deploy --reset-values --create-namespace
```


Test the test helm chart like so:

```
helm upgrade --debug --dry-run -f ./src/helm/beacon-with-db/values.yaml my-test-deploy ./src/helm/beacon-with-db -i -n my-test-deploy --reset-values
```

Manage and uninstall helm chart like so:

```
helm list -A

helm uninstall my-test-deploy -n my-test-deploy
```

Useful Kube commands for debugging

```
kubectl get pods -n my-test-deploy
kubectl get deployments -n my-test-deploy
kubectl get services -n my-test-deploy

kubectl describe deployment/beaconwithdb-deployment-mainbeaconservice -n my-test-deploy

kubectl logs deploy/beaconwithdb-deployment-mainbeaconservice -n my-test-deploy -f
```


**Note: For the Cosmos DB emulator**
* Can't yet get this working in its own deployment without a lot of faff based on [Linux-based emulator (preview)](https://learn.microsoft.com/en-us/azure/cosmos-db/emulator-linux#docker-commands).
* For now this runs in the same deployment as part of the Beacon service (will restart on every beacon service failure)

Port forward like so:
```
kubectl port-forward pod/beaconwithdb-deployment-mainbeaconservice-788fd9585c-2tk56 5001:80 -n my-test-deploy  (for main service)

kubectl port-forward pod/beaconwithdb-deployment-mainbeaconservice-788fd9585c-2tk56 5004:1234 -n my-test-deploy (for cosmos emulator UI)
```