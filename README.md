# Azure Data Factory Automation

## Automation PowerShell script example for automating Azure Data Factory pipelines.

### This repository contains sample PowerShell scripts to automate Azure Data Factory pipelines deployment by using json templates for greater flexibility as opposed to maintaining a big monolithic ARM template.

The automation scripts can be used to templatize the linked services, data sets and pipelines with placeholders which would be dynamically populated and updated in the json template files and deployed to ADF. 

## Prerequisites:

The following are the pre-requisite steps required to configure the json files before running the automation script:

1. Open the **ADF Json Files** folder inside the **Templates** folder.

This folder contains various json template files for different types of linked services, data sets & ADF pipelines.
The files are not named as such but one can re-name them with a suitable name to identify it's purpose & also add other template files at this location ex: other data set templates, linked service templates and multiple ADF pipeline definition json template files.
Currently basic template files are present which have template definitions with placeholder values. These placeholder values are populated by the deployment script and updated json template files are saved and written to **UpdatedJsonTemplatesLocation** folder with same filename for deployment.

The following are the json template files:

* **{aml linked service name}.json** : json template for Azure Machine Learning experiment linked service (provides AML webservice endpoint and API key to the ADF pipeline)
* **{azure batch linked service name}.json** : json template for Azure Batch service (provides Azure batch service details to the ADF pipeline)
* **{azure sql linked service name}.json** : json template file for Azure SQL database (provides connection string to Azure SQL database to ADF pipeline)
* **{data set 1 name}.json** : sample data set json template
* **{pipeline 1 name}.json** : sample ADF pipeline json template
* **{storage linked service name}.json** : json template file for Azure storage (provides connection string to Azure Storage to ADF pipeline)

2. Ensure all the Azure PaaS components required by the linked service are provisioned wiz. Azure Batch account / service, ADF service, Azure SQL Db, Azure Storage Account, AML experiments published as web service in AML workspace & A service principal account with contributor access to the resource group containing these resources.

3. Open the **Templates** folder to configure the following 3 json configuration files:

* **AMLExperiments.json** : This file will provide the list of Azure Machine Learning Experiments that are to be deployed as linked services. In case of one experiment, it will have only one entry in the **AMLExperiments** array object.
Replace the value of **EXP_name** variable with the name of the Azure Machine Learning Experiment name.
Add as many objects with **EXP_name** initialized as the number of experiments to be deployed.
Now name the **LS_name** field as the desired name of the linked service for the given experiment. This entry for the linked service name must also be present in the **azureMLLinkedServiceFileName** array in **ADF.Parameters.Common** json template file.

* **ADF.Parameters.Common.json** : This file provides the building blocks for the ADF pipeline. Configure the below properties in the **parameters** object as follows:
**storageLinkedServiceFileName** : Name of storage linked service json template file (same as that defined in **ADF Json Files**)
**azureSqlServiceLinkedFileName** : Name of SQL linked service json template file (same as that defined in **ADF Json Files**)
**azureBatchLinkedServiceFileName** : Name of Batch linked service json template file (same as that defined in **ADF Json Files**)
**azureMLLinkedServiceFileName** : Name of AML linked service json template file (same as that defined in **ADF Json Files**)
**datasets** : Name of data sets json template files (same as that defined in **ADF Json Files**)
**pipelines** : Name of pipelines json template files (same as that defined in **ADF Json Files**)
**pipelineStartTime** : The pipeline start UTC timestamp
**pipelineEndTime** : The pipeline end UTC timestamp
**isFullDeployment** : Boolean flag set to true

* **ADF.Parameters_Dev.json** : This file provides configuration values to be consumed by linked service templates. These configurations should either be hardcoded or dynamically populated before execution of ADF deployment script. 
The following are the configuration properties required:

* **dataFactoryName** : Azure Data Factory Name
* **dataFactoryHubName** : Azure Data Factory Hub Name 
* **resourceGroupName**	: Name of Azure Resource Group
* **environmentTag** : Name of environment tag (dev in this case)
* **datafactoryLocation** : Azure Data Factory Location
* **storageAccountName** : Name of storage account
* **storageAccountKey**	: Storage account key 
* **batchAccountName** : Name of Azure Batch Account
* **batchAccountKey** : Batch Account key 
* **batchAccountPoolName** : Name of batch account pool
* **batchURI** : Batch URI 
* **amlConfiguration** : Azure Machine Learning configuration (Name the **amlName** property for each object in the array as the name of the AML experiment & either hardcode the values for **amlApiKey** & **amlEndpoint** properties of each object as the web service end point and API key respectively for a given AML experiment, the same can also be populated by AML automation script as discussed here https://github.com/amanbedi18/Azure-MachineLearning-Automation)
* **datahubSqlServerName** : Name of Azure SQL Server instance
* **datahubDatabaseName** : Name of Azure SQL Database
* **datahubSqlServerAdminLogin** : SQL Server Admin Login 
* **datahubSqlServerAdminLoginPassword** : SQL Server Admin Password 
* **datahubSqlServerReadOnlyLogin** : SQL Server Admin Read Only Login 
* **datahubSqlServerReadOnlyLoginPassword** : SQL Server Admin Read Only Password 

## Script Execution

### Once the pre-configuration steps are complete, the **ADF.PublishAllAssets.ps1** can be invoked with the following arguments:

* **env** : Environment Identifier (dev in this case)
* **sourceFilesPath** : Path to **ADF Json Files** folder.
* **templateFilePath** : Path to **Templates** folder.
* **deploymentFolderPath** : Path to **UpdatedJsonTemplatesLocation** folder.
* **MLFileName** : ALM Experiments json file name.
* **ClientId** : The app client Id of the service principal.
* **resourceAppIdURI** : The resource app id uri of the service principal.
* **TenantId** : The tenant Id.
* **ClientKey** : The service principal client Key.

### This script logs-in to Azure environment with provided service principal details and executes the following 4 PowerShell scripts in the same order:

1. **Remove-ADF.AllAssets.PS1** :  This script removes all the data sets, linked services and pipelines in a given ADF service.

* The script obtains all the items in ADF to be removed from **ADF.Parameters.Common.json** & the ADF details from **ADF.Parameters_dev.json**
* It then iterates over each data set and pipeline obtained from the template file and deletes the same from ADF.

2. **New-ADF.LinkedServicesDeployment.PS1** : This script deploys all linked services to ADF.

* The script obtains all linked service configurations from **ADF.Parameters_dev.json** & all linked service template file names (which will also be used as the linked service names) from **ADF.Parameters.Common.json**
* The script will create the storage, SQL & Batch linked service by parsing the storage, SQL & Batch linked service template files respectively, populating the necessary configuration values in the placeholders of the template file, saving the updated template file in destinationPath (always pointing to the path of the folder **UpdatedJsonTemplatesLocation**) and deploying the linked services.
* The script will then create the AML linked service. It will fetch the AML experiment details from **ADF.Parameters_Dev.json**  & then generate linked service template for each AML experiment in **AMLExperiments** array object in **AMLExperiments.json** with the name being the same as **LS_name** for a given experiment name as **EXP_name** with its details corresponding to  web service endpoint and API key in **amlConfiguration** array of the **ADF.Parameters_Dev.json**  for given AML experiment matched by **amlName** property.
Each AML experiment's linked service file is again saved in destinationPath (always pointing to the path of the folder **UpdatedJsonTemplatesLocation**) and the linked service for each experiment is deployed.

3. **New-ADF.DatasetsDeployment.PS1** : This script deploys all the data sets to ADF.

* The script obtains all ADF configurations from **ADF.Parameters_dev.json** & all data set template file names (which will also be used as the data set name) from **ADF.Parameters.Common.json**
* It then iterates over each data set json template file and deploys the same.

3. **New-ADF.PipelineDeployment.PS1** : This script deploys all the pipelines to ADF.

* The script obtains all ADF configurations from **ADF.Parameters_dev.json** & all pipelines template file names (which will also be used as the pipeline name) from **ADF.Parameters.Common.json**
* It then iterates over each pipeline json template file and deploys the same.

**After successful execution, the desired ADF pipeline is deployed with updated configurations / changes.**
