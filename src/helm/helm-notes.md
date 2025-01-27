# Helm Chart Commands

Install the test helm chart like so:

```
helm upgrade --debug --dry-run -f ./src/helm/testdeploy/values.yaml my-test-deploy ./src/helm/testdeploy -i -n my-test-deploy --reset-values
```