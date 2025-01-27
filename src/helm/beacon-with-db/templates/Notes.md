# Helm Chart Commands

Install the test helm chart like so:

```
helm upgrade --debug --dry-run -f ./src/helm/beacon-with-db/values.yaml my-test-deploy ./src/helm/beacon-with-db -i -n my-test-deploy --reset-values
```

Can also use the `--disable-openapi-validation` flag to test when something does not make sense like so

```
helm upgrade --debug --disable-openapi-validation --dry-run  -f ./src/helm/beacon-with-db/values.yaml my-test-deploy ./src/helm/beacon-with-db -i -n my-test-deploy --reset-values
```

To install for real
```
helm upgrade -f ./src/helm/beacon-with-db/values.yaml my-test-deploy ./src/helm/beacon-with-db -i -n my-test-deploy --reset-values --create-namespace
```

To uninstall
```
helm uninstall my-test-deploy -n my-test-deploy
```


Useful kubectl commands
```
kubectl get pods -n my-test-deploy
kubectl get deployments -n my-test-deploy

kubectl describe deployment/beaconwithdb-deployment-mainbeaconservice -n my-test-deploy
kubectl describe pod/beaconwithdb-deployment-mainbeaconservice-66ff8ff5cf-vvmvq -n my-test-deploy

kubectl logs deploy/beaconwithdb-deployment-mainbeaconservice -n my-test-deploy -f

kubectl port-forward deploy/beaconwithdb-deployment-mainbeaconservice 5000:80 -n my-test-deploy
```