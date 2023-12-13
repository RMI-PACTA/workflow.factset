# workflow.pacta

## Running container

```sh
docker run -i -t --rm --env-file=.env -v ./foo:/mnt/factset-data IMAGE_NAME
```

```sh
# change this value as needed.
RESOURCEGROUP="myResourceGroup"

# run from repo root

az deployment group create --resource-group "$RESOURCEGROUP" --template-file azure-deploy.json --parameters @azure-deploy.parameters.json

```
