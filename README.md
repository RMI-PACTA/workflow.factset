# workflow.factset

This repo contains the `workflow.factset` R package, a Dockerfile to build an image containing that package and its dependencies, and an Azure ARM template to deploy that image, along with [factset_data_loader](https://github.com/RMI-PACTA/factset_data_loader/) and a PostgreSQL database.

**QUICKSTART**: See ["Deploy"](#Deploy), below.

## `workflow.factset` R package

The `workflow.factset` package's purpose is to extract data from a database prepared by the FactSet DataFeed Loader application.
For more information on that application, and a docker container to use is efficiently, please see [RMI-PACTA/factset_data_loader](https://github.com/RMI-PACTA/factset_data_loader/).

The primary callable function in the package is `export_pacta_files()`, which serves as a wrapper around more-targeted functions which download data from the database in a format expected by [`pacta.data.preparation`](https://github.com/RMI-PACTA/pacta.data.preparation).
`export_pacta_files()` then writes those in-memory tables to files.
Databases other than PostgreSQL may work, but are not tested.

The default values to control behavior of `export_pacta_files()` (and the related `connect_factset_db()`) are controlled by OS Environment variables, but use the standard R argument system if you are including these functions in a flow other than the one implemented in the Docker image in this repo.

### Environment variables to control default behavior

* `DATA_TIMESTAMP`:
  String.
  Date to use for share prices, fund holdings, and entity financing information.
  Exact format flexible, but should be parseable by `lubridate::ymd_hms()`
* `ISS_REPORTING_YEAR`:
  Integer.
  Year to use for ISS reporting data.
* `DEPLOY_START_TIME`:
  String, optional (default `Sys.time()`).
  Provides identifier to distinguish between dataset pulled from database at different times.
  Suggested format:
  `"%Y%m%dT%H%M%SZ"` (this is the default format used by the ARM template described below).
* `EXPORT_DESTINATION`:
  Filepath.
  Directory where exported PACTA data files are saved.
  `export_pacta_files()` will create a new directory underneath this path.
* `LOG_LEVEL`:
  String, optional (default `"INFO"`).
  Not actually used by any of the functions in this package, but used in docker image to set logging verbosity of the package.
  Suggested values: `"INFO"`, `"DEBUG"`, `"TRACE"`.
* `PGDATABASE`:
  String.
  Database name containing FactSet tables.
* `PGHOST`:
  Hostname.
  Server address for FactSet database.
* `PGPASSWORD`:
  String.
  Password for connection to DB.
* `PGPORT`:
  Integer, optional (default `5432`).
  Port on DB server to access PostgreSQL.
* `PGUSER`:
  String.
  PostgreSQL username.
  User must have READ access to tables.
* `UPDATE_DB`:
  `true`/`false`, optional (default `false`).
  Delay main function body until a file (`$WORKINGSPACEPATH/done_loader`) exists.
  Useful as part of ARM template, when this repo's docker image runs simultaneously with the [RMI-PACTA/factset_data_loader](https://github.com/RMI-PACTA/factset_data_loader/) image, which may take hours to finish preparing the database.
* `WORKINGSPACEPATH`:
  Filepath.
  Used when `$UPDATE_DB` is `true`.

## Docker image

The Docker image defined in `Dockerfile` contains all required dependencies for interacting with `PostgreSQL` databases, and have been tested against Azure Flexible Server for PostgreSQL (See ARM Template, below).

**Note:** Setting the `LOG_LEVEL` Environment Variable for the docker container is useful for controlling the verbosity of the logs.

The image builds automatically by GitHub actions, and hosted publicly on `ghcr.io`.
See "Packages", to the right.
The `main` tag should be used, rather than `latest`.

## Azure ARM template

`azure-deply.json` is an [Azure ARM Template](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) which by default deploys:

* Azure Flexible Server for PostgreSQL
  * `fds` database on that server
  * Firewall rule allowing access to the server from Azure (such as the containers)
* `factset_data_loader` docker image (image from `ghcr.io`)
* `workflow.factset` docker image (image from `ghcr.io`, this repo)

Alternately, the deploy template will only deploy the docker container from this repo's image if the `updateDB` parameter is set to `false` (see "Parameters and Variables", below).

### Prerequisites

* (Local) `az` CLI: available [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* Storage Account: A storage account must exist, with File Shares (referenced in the existing ARM template as `"factset-loader"` and `"factset-extracted"`).
  * File Share `factset-loader`: see [RMI-PACTA/factset_data_loader](https://github.com/RMI-PACTA/factset_data_loader/) for more information on expected structure
  * File Share `factset-extracted`: No structure expected. `export_pacta_files()` will create subdirectories in this file share.
* Managed Identity: An Azure managed identity must exist with read/write (contributor) permissions for the fileshares.
  This is the identity that the containers will run with.

### Parameters and Variables

ARM Template Parameters can be set at deploy-time to control the properties of the deployed resources.
The `azure-deploy.json` template in this repo makes use of them to pass information to the containers and database.
All parameters must have values, but most have sensible defaults already defined in the template, and the rest have example values defined in `azure-deploy.example.parameters.json`.

#### Parameters

* `PGHOSTOverride`: If `updateDB` is `false`, then this specifies the value of `$PGHOST` environment variable that `workflow.factset` will connect to.
* `PGPASSWORD`: Database Server Password
* `containerGroupName`: Label to define the container group name, and by default the DB server name will have this appended with `-postgres`.
    Does not affect behavior of container, but note for later, so resources can be deleted/managed via Azure Portal or through `az`.
* `dataTimestamp`: Passed to containers as $DATA_TIMESTAMP environment variable.
* `identity`: See "Identity" in "Prerequisites", above.
* `imageTagLoader`: (default: `main`) tag used for `factset_data_loader` image from `ghcr.io`
* `imageTagWorkflow`: (default: `main`) tag used for `workflow.pacta` image from `ghcr.io`
* `loaderDBBackup`: (default: 1) Should `factset_data_loader` pg_dump the database after updating? Empty string disables backup.
* `loaderDBRestore`: (default: 1) Should `factset_data_loader` pg_restore the database before updating? Empty string disables restore.
* `loaderFactsetSerial`: Subscription serial number (provided by FactSet)
* `loaderFactsetUsername`: Subscription username (provided by FactSet)
* `location`: (default: same as Resource Group) What Azure zone should resources be deployed in?
* `restartPolicy`: See [Azure Documentation](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-restart-policy)
* `starttime`: (default: `utcNow()`) Provides useful unique identifier to distinguish between datasets.
* `storageAccountKeyRawdata`: Account key to Azure Storage Account (see "Prerequisites").
* `updateDB`: `true` or `false` (default: `true`). If `false`, does not deploy DB or `factset_data_loader` container, and `export_pacta_files()` does not wait for signal from loader before attempting to extract data. Useful when targeting an existing populated database.

### Variables

Variables in ARM templates are populated at deploy-time (can be influenced by parameters), but can only be edited in the ARM template itself. Many of the variables used in this template are detailed in the [factset_data_loader repo](https://github.com/RMI-PACTA/factset_data_loader).

Key variables to be aware of:

* `containerregistry`: Defines the container registry images will be pulled from. If using a private registry, be sure to check the ARM template documentation about registry credentials
* `dbInstanceType`: Defines the machine specifications for DB server
* `dbSkuSizeGB`: In testing, even with "AutoGrow" enabled, values less than 256 GB caused out of space errors when running in production
* `machineCpuCoresLimit*`: Maximum CPU cores available to each container. Note that currently ACI container groups are limited to a maximum of 4 cores (across all containers).
* `machineCpuCoresRequest*`: Cores allocated to each container. Note that for the Loader container, this also affect the parallelization level of the loader (and overall run time).
* `machineMemoryInGBLimit*`: Maximum memory available to each container. Note that currently ACI container groups are limited to a maximum of 16GB (across all containers).
* `machineMemoryInGBRequest*`: Memory requested by each container. Actual usage may fall below this, and be used by other containers (up to their limit)
* `mountPathExport`: Path in container to export files to

### Deploy

Optional: Create a parameters file (`azure-deploy.example.parameters.json` serves as a template) for parameters that do not have a default.
If you do not create this file, then the deploy process will prompt for values.

A parameter file with the values that the RMI-PACTA team uses for extracting data is available at [`azure-deploy.rmi-pacta.parameters.json`](azure-deploy.rmi-pacta.parameters.json).

```sh
# run from repo root

# change this value as needed.
RESOURCEGROUP="RMI-SP-PACTA-DEV"

# Users with access to the RMI-PACTA Azure subscription can run:
az deployment group create --resource-group "$RESOURCEGROUP" --template-file azure-deploy.json --parameters azure-deploy.rmi-pacta.parameters.json

```

For security, the RMI-PACTA parameters file makes heavy use of extracting secrets from an Azure Key vault, but an example file that passes parameters "in the clear" is available as [`azure-deploy.example.parameters.json`](azure-deploy.example.parameters.json)

Non RMI-PACTA users can define their own parameters and invoke the ARM Template with:

```sh
# Otherwise:
# Prompts for parameters without defaults
az deployment group create --resource-group "$RESOURCEGROUP" --template-file azure-deploy.json 

# if you have created your own parameters file:
az deployment group create --resource-group "$RESOURCEGROUP" --template-file azure-deploy.json --parameters @azure-deploy.parameters.json
```

## Local Development

### Build

Note that the image supports `amd64` platforms.
If you are running on an `arm64` machine (Apple Silicon), you may need to change the preferrred build platform with:

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

To build the image, you can use the standard mechanism of `docker build .`.
To build and test in one step, you can alternately use `docker-compose up --build`

### Testing

Partial (manual) local testing is possible via `docker-compose`.
Currently `get_issue_code_bridge()` is the sole function with necessary testing infrastructure.

Testing Steps:

```sh
docker-compose up
```

```sh
# in another terminal:
docker attach workflowfactset-workflow.factset-1 # enters the workflow.factset container
```

This enters the container, which is running R in an interactive session

```r
#in that container
library(workflow.factset)
conn <- connect_factset_db()
issue_code_bridge <- get_issue_code_bridge(conn = conn)
issue_code_bridge
```

From here, you can exit R as usual (`q()`), and then turn off the database container with:

```sh
docker-compose down --volumes
```

## Exported Files

The files exported by `workflow.factset::export_pacta_files()` are:

### factset_entity_financing_data.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|fsym_id|chr|"XXXXXX-R"|FactSet identifier for security|
|date|date|2022-12-31|date of balance sheet data|
|currency|chr|"USD"|currency for balance sheet data|
|ff_mkt_val|dbl|2000000|Market Value - based on latest closing price and monthly shares|
|ff_debt|dbl|1000000|Total debt|
|fsym_company_id|chr|"XXXXXX-S"|fsym_id connecting to FactSet Fundamentals dataset|
|factset_entity_id|chr|"XXXXXX-E"|FactSet identifier for an entity|

### factset_entity_info.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|factset_entity_id|chr|"XXXXXX-E"| FactSet identifier for an entity|
|entity_proper_name|chr|"FooBar, Inc."|Entity common name, normalized and in proper case|
|iso_country|chr|"US"|2 letter country code for domicile|
|sector_code|chr|"6000"|4 digit code for FactSet sector classification|
|factset_sector_desc|chr|"Miscellaneous"|FactSet description for sector|
|industry_code|chr|"6005"|4 digit code for FactSet industry classification|
|factset_industry_desc|chr|"Miscellaneous"|FactSet description for industry|
|credit_parent_id|chr|"XXXXXX-E"|FactSet entity ID for credit parent|
|ent_entity_affiliates_last_update|chr|"2023-12-21T22:35:27Z"|Timestamp for last update of `ent_entity_affiliates` table|

### factset_financial_data.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|fsym_id|chr|"XXXXXX-S"| FactSet identifier for financial instrument|
|isin|chr|"XX0000000001"|ISIN for instrument|
|factset_entity_id|chr|XXXXXX-E| FactSet identifier for an entity|
|adj_price|dbl|100.5|Adjusted Share price|
|adj_shares_outstanding|dbl|NA|Adjusted number of shares outstanding|
|issue_type|chr|NA|Share Type|
|one_adr_eq|dbl|NA|Number of shares equivilent to one ADR|

### factset_fund_data.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|factset_fund_id|chr|"FFFFFF-E"|FactSet identifier for fund|
|fund_reported_mv|dbl|100000000|Total reported Market Value|
|holding_isin|chr|"XX0000000002"|ISIN held in fund|
|holding_reported_mv|dbl|100000|Market value of ISIN held in fund|
|report_date|date|2023-12-31|report date for holding|

### factset_isin_to_fund_table.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|isin|chr|"XX0000000001"|ISIN|
|fsym_id|chr|"XXXXXX-S"| FactSet identifier for financial instrument|
|factset_fund_id|chr|"FFFFFF-E"|FactSet identifier for fund|

### factset_iss_emissions.rds

|Column Name|Column Type|Example Content|Description|
|---|---|---|---|
|factset_entity_id|chr|"XXXXXX-E"| FactSet identifier for an entity|
|icc_total_emissions|dbl|123.4|Total emissions for entity|
|icc_scope_3_emissions|dbl|123.4|Scope 3 emissions for entity|
