<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
				
		File:		New-ADF.LinkedServicesDeployment.ps1
		
		Purpose:	Azure Data Factory - Azure Deployment Automation Script
		
		Version: 	1.0.0.4 - 12th October 2017 - Release Deployment Team
		==============================================================================================

	.SYNOPSIS
		Azure Data Factory - Azure Deployment Automation Script
	
	.DESCRIPTION
		Azure Data Factory - Azure Deployment Automation Script
				
		Deployment steps of the script are outlined below.
		1) Loads templateParameters  
		2) Loads commonTemplateParameters
		3) Create new Azure Data Factory Linked Services
		    
	.PARAMETER env 
        Specify the environment name like dev, prod, uat'   
        	
	.PARAMETER sourceFilesPath
		Specify the location of source files
			
	.PARAMETER templateFilePath
		Specify the location of template file
			
	.PARAMETER deploymentFolderPath
		Specify the location of deployment folder
	
	.PARAMETER MLFileName
		Specify the location of machine learning experiments name file
				
	.EXAMPLE
		Default:
            C:\PS> New-ADF.LinkedServicesDeployment.ps1 -env <"env"> `
            -sourceFilesPath <"sourceFilesPath"> `
            -templateFilePath <"templateFilePath"> `
			-deploymentFolderPath <"deploymentFolderPath"> `
			-MLFileName <"MLFileName">
#>

#region - Global Variables
param
(
	[Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Specify the environment name like dev, prod, uat')]
	[String]$env,
	[Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Specify the location of source files')]
	[String]$sourceFilesPath,
	[Parameter(Position = 2, Mandatory = $True, HelpMessage = 'Specify the location of template file')]
	[String]$templateFilePath,
	[Parameter(Position = 3, Mandatory = $True, HelpMessage = 'Specify the location of deployment folder')]
	[String]$deploymentFolderPath,
	[Parameter(Position = 4, Mandatory = $True, HelpMessage = 'Specify the location of machine learning experiments name file')]
	[String]$MLFileName
)

$templateParametersFile = "$templateFilePath\ADF.Parameters_$env.json"
$commonTemplateParametersFile = "$templateFilePath\ADF.Parameters.Common.json"
$amlNamesFilePath = "$templateFilePath\" + $MLFileName
#endregion

#region - Functions
<#
 ==============================================================================================	 
	Script Functions
		CreateStorageLinkedService				- Creates the storage account linked service configuration
		CreateAzureSqlLinkedService				- Creates the AzureSQL Linked Service 
		CreateBatchLinkedService				- Creates the Batch Linked Service 
		CreateAMLLinkedService					- Creates the Batch Linked Service (AML)	
 ==============================================================================================	
#>
function CreateStorageLinkedService
{
	[CmdletBinding()]
	param
	(
		[String]$StorageAccountName,
		[String]$StorageAccountKey,
		[String]$DataHubName,
		[String]$DataFactoryName,
		[String]$ResourceGroupName,
		[String]$StorageLinkedServiceFileName
	)
	
	#region - Create Storage Linked Service
	$sourcePath = "$sourceFilesPath\$StorageLinkedServiceFileName.json"
	Write-Output $sourcePath
	$adpStorageLinkedService = Get-Content -Path $sourcePath -Raw | ConvertFrom-JSON
	
	$connectionString = "DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}" -f $storageAccountName, $StorageAccountKey
	$adpStorageLinkedService.properties.typeProperties.connectionString = $connectionString
	if ($adpStorageLinkedService.properties.hubName)
	{
		$adpStorageLinkedService.properties.hubName = $DataHubName
	}
	$destinationPath = "$deploymentFolderPath\$ResourceGroupName-adpStorageLinkedService.json"
	Write-Verbose "Writing $destinationPath with account details"
	
	$adpStorageLinkedService | ConvertTo-JSON | Out-File -filepath $destinationPath -Force
	$Parameters = @{
		ResourceGroupName	  = $ResourceGroupName
		DataFactoryName	      = $DataFactoryName
		File				  = $destinationPath
	}
	New-AzureRmDataFactoryLinkedService @Parameters -Force
	#endregion
}

function CreateAzureSqlLinkedService
{
	[CmdletBinding()]
	param
	(
		[String]$ServerName,
		[String]$DatabaseName,
		[String]$Username,
		[String]$Password,
		[String]$DataHubName,
		[String]$DataFactoryName,
		[String]$ResourceGroupName,
		[String]$AzureSqlServiceLinkedFileName
	)
	
	#region - Create Azure Sql LinkedService
	$sourcePath = "$sourceFilesPath\$AzureSqlServiceLinkedFileName.json"
	Write-Output $sourcePath
	$adpAzureSqlLinkedService = Get-Content -Path $sourcePath -Raw | ConvertFrom-JSON
	
	$connectionString = "Data Source=tcp:{0}.database.windows.net,1433;Initial Catalog={1};Integrated Security=False;User ID={2};Password={3};Connect Timeout=30;Encrypt=True" -f $ServerName, $DatabaseName, $Username, $Password
	$adpAzureSqlLinkedService.properties.typeProperties.connectionString = $connectionString
	if ($adpAzureSqlLinkedService.properties.hubName)
	{
		$adpAzureSqlLinkedService.properties.hubName = $DataHubName
	}
	$destinationPath = "$deploymentFolderPath\$ResourceGroupName-adpAzureSqlLinkedService.json"
	Write-Verbose "Writing $destinationPath with account details"
	
	$adpAzureSqlLinkedService | ConvertTo-JSON | Out-File -filepath $destinationPath -Force
	$Parameters = @{
		ResourceGroupName	  = $ResourceGroupName
		DataFactoryName	      = $DataFactoryName
		File				  = $destinationPath
	}
	New-AzureRmDataFactoryLinkedService @Parameters -Force
	#endregion
}

function CreateBatchLinkedService
{
	[CmdletBinding()]
	param
	(
		[String]$AccountName,
		[String]$AccessKey,
		[String]$PoolName,
		[String]$BatchUri,
		[String]$AzureBatchLinkedFileName,
		[String]$StorageLinkedServiceFileName,
		[String]$DataHubName,
		[String]$DataFactoryName,
		[String]$ResourceGroupName
	)
	
	#region - Create Batch Linked Service
	$sourcePath = "$sourceFilesPath\$AzureBatchLinkedFileName.json"
	Write-Output $sourcePath
	$adpAzureBatchLinkedService = Get-Content -Path $sourcePath -Raw | ConvertFrom-JSON
	
	$adpAzureBatchLinkedService.properties.typeProperties.accountName = $AccountName
	$adpAzureBatchLinkedService.properties.typeProperties.accessKey = $accessKey
	$adpAzureBatchLinkedService.properties.typeProperties.poolName = $PoolName
	$adpAzureBatchLinkedService.properties.typeProperties.linkedServiceName = $StorageLinkedServiceFileName
	$adpAzureBatchLinkedService.properties.typeProperties.batchUri = $BatchUri
	if ($adpAzureBatchLinkedService.properties.hubName)
	{
		$adpAzureBatchLinkedService.properties.hubName = $DataHubName
	}
	$destinationPath = "$deploymentFolderPath\$ResourceGroupName-adpAzureBatchLinkedService.json"
	Write-Verbose "Writing $destinationPath with account details"
	Write-Output "Creating batch linked service now"
	$adpAzureBatchLinkedService | ConvertTo-JSON | Out-File -filepath $destinationPath -Force
	
	$Parameters = @{
		ResourceGroupName	  = $ResourceGroupName
		DataFactoryName	      = $DataFactoryName
		File				  = $destinationPath
	}
	New-AzureRmDataFactoryLinkedService @Parameters -Force
	#endregion
}

function CreateAMLLinkedService
{
	[CmdletBinding()]
	param
	(
		[String]$DataHubName,
		[String]$DataFactoryName,
		[String]$ResourceGroupName
	)
	
	$experimentsForLS = $commonTemplateParameters.parameters.azureMLLinkedServiceFileName.value
	
	foreach ($experiment in $experimentsForLS)
	{
		#region - Create AML Linked Service
		Write-Output "Inside Function"
		$sourcePath = "$sourceFilesPath\$experiment.json"
		Write-Output $sourcePath
		$adpAzureMLLinkedService = Get-Content -Path $sourcePath -Raw | ConvertFrom-JSON
		$currentExperimentName = ($amlExperiments | Where-Object { $PSItem.LS_name -eq $experiment }).EXP_name
		$adpAzureMLLinkedService.properties.typeProperties.MlEndpoint = ($templateParameters.parameters.amlConfiguration | Where-Object { $PSItem.amlName -eq $currentExperimentName }).amlEndPoint.value
		$adpAzureMLLinkedService.properties.typeProperties.ApiKey = ($templateParameters.parameters.amlConfiguration | Where-Object { $PSItem.amlName -eq $currentExperimentName }).amlApiKey.value
		if ($adpAzureMLLinkedService.properties.hubName)
		{
			$adpAzureMLLinkedService.properties.hubName = $DataHubName
		}
		$destinationPath = "$deploymentFolderPath\$experiment.json"
		Write-Verbose "Writing $destinationPath with account details"
		
		$adpAzureMLLinkedService | ConvertTo-JSON | Out-File -filepath $destinationPath -Force
		$Parameters = @{
			ResourceGroupName	  = $ResourceGroupName
			DataFactoryName	      = $DataFactoryName
			File				  = $destinationPath
		}
		New-AzureRmDataFactoryLinkedService @Parameters -Force
	}
	#endregion
}
#endregion

#region - Control Routine

#region -  Load Parameters
$templateParameters = Get-Content -Path $templateParametersFile -Raw | ConvertFrom-JSON
if (-not $templateParameters)
{
	throw "ERROR: Unable to retrieve ADP Template parameters file. Terminating the script unsuccessfully."
}

$commonTemplateParameters = Get-Content -Path $commonTemplateParametersFile -Raw | ConvertFrom-JSON
if (-not $commonTemplateParameters)
{
	throw "ERROR: Unable to retrieve ADP Common Template parameters file. Terminating the script unsuccessfully."
}

$amlNames = Get-Content -Path $amlNamesFilePath -Raw | ConvertFrom-JSON
if (-not $amlNames)
{
	throw "ERROR: Unable to retrieve AML Names file. Terminating the script unsuccessfully."
}
$amlExperiments = @()
foreach ($exp in $amlNames.AMLExperiments)
{
	$amlExperiments += $exp
}
#endregion

#region - Azure Data Factory Service Settings
$dataFactoryName = $templateParameters.parameters.dataFactoryName.value
$dataFactoryHubName = $templateParameters.parameters.dataFactoryHubName.value
$resourceGroupName = $templateParameters.parameters.resourceGroupName.value
#endregion

#region - Storage Linked Service settings
$storageAccountName = $templateParameters.parameters.storageAccountName.value
$storageAccountKey = $templateParameters.parameters.storageAccountKey.value

$storageLinkedServiceFileName = $commonTemplateParameters.parameters.storageLinkedServiceFileName.value
#endregion

#region - Azure Sql Linked Service settings
$datahubSqlServerName = $templateParameters.parameters.datahubSqlServerName.value
$datahubDatabaseName = $templateParameters.parameters.datahubDatabaseName.value
$datahubSqlServerAdminLogin = $templateParameters.parameters.datahubSqlServerAdminLogin.value
$datahubSqlServerAdminLoginPassword = $templateParameters.parameters.datahubSqlServerAdminLoginPassword.value

$azureSqlServiceLinkedFileName = $commonTemplateParameters.parameters.azureSqlServiceLinkedFileName.value
#endregion

#region - Azure Batch Linked Service settings
$AccountName = $templateParameters.parameters.batchAccountName.value
$AccessKey = $templateParameters.parameters.batchAccountKey.value
$PoolName = $templateParameters.parameters.batchAccountPoolName.value
$BatchUri = $templateParameters.parameters.batchURI.value

$AzureBatchLinkedFileName = $commonTemplateParameters.parameters.azureBatchLinkedServiceFileName.value
#endregion

#region - Create linked services
Write-Output "Generating storage linked service"
$Parameters = @{
	StorageAccountName			     = $storageAccountName
	StorageAccountKey			     = $storageAccountKey
	DataHubName					     = $dataFactoryHubName
	DataFactoryName				     = $dataFactoryName
	ResourceGroupName			     = $resourceGroupName
	StorageLinkedServiceFileName	 = $storageLinkedServiceFileName
}
CreateStorageLinkedService @Parameters

Write-Output "Generating Azure Sql linked service"
$Parameters = @{
	ServerName					      = $datahubSqlServerName
	DatabaseName					  = $datahubDatabaseName
	Username						  = $datahubSqlServerAdminLogin
	Password						  = $datahubSqlServerAdminLoginPassword
	DataHubName					      = $dataFactoryHubName
	DataFactoryName				      = $dataFactoryName
	ResourceGroupName				  = $resourceGroupName
	AzureSqlServiceLinkedFileName	  = $azureSqlServiceLinkedFileName
}
CreateAzureSqlLinkedService @Parameters

Write-Output "Generating Azure Batch linked service"
$Parameters = @{
	AccountName					     = $AccountName
	AccessKey					     = $AccessKey
	PoolName						 = $PoolName
	BatchUri						 = $BatchUri
	AzureBatchLinkedFileName		 = $AzureBatchLinkedFileName
	StorageLinkedServiceFileName	 = $storageLinkedServiceFileName
	DataHubName					     = $dataFactoryHubName
	DataFactoryName				     = $dataFactoryName
	ResourceGroupName			     = $resourceGroupName
}
CreateBatchLinkedService @Parameters

Write-Output "Generating Azure ML linked service"
$Parameters = @{
	DataHubName			      = $dataFactoryHubName
	DataFactoryName		      = $dataFactoryName
	ResourceGroupName		  = $resourceGroupName
}
CreateAMLLinkedService @Parameters
#endregion 

#endregion
