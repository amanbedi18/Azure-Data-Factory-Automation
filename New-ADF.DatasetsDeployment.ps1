<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
				
		File:		New-ADF.DatasetsDeployment.ps1
		
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
		3) Creates a new data set in Azure Data Factory
				    
	.PARAMETER env 
        Specify the environment name like dev, prod, uat'   
        	
	.PARAMETER sourceFilesPath
		Specify the location of source files
			
	.PARAMETER templateFilePath
		Specify the location of template file
			
	.PARAMETER deploymentFolderPath
		Specify the location of deployment folder
	
	.EXAMPLE
		Default:
            C:\PS> New-ADF.DatasetsDeployment.ps1 -env <"env"> `
            -sourceFilesPath <"sourceFilesPath"> `
            -templateFilePath <"templateFilePath"> `
            -deploymentFolderPath <"deploymentFolderPath">          
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
	[String]$deploymentFolderPath
)


$templateParametersFile = "$templateFilePath\ADF.Parameters_$env.json"
$commonTemplateParametersFile = "$templateFilePath\ADF.Parameters.Common.json"

$templateParameters = Get-Content -Path $templateParametersFile -Raw | ConvertFrom-JSON
if (-not $templateParameters)
{
	throw "ERROR: Unable to retrieve ADP Template parameters file. Terminating the script unsuccessfully."
}

$dataFactoryName = $templateParameters.parameters.dataFactoryName.value
$resourceGroupName = $templateParameters.parameters.resourceGroupName.value
$datasets = $commonTemplateParameters.parameters.datasets.value

$commonTemplateParameters = Get-Content -Path $commonTemplateParametersFile -Raw | ConvertFrom-JSON

if (-not $commonTemplateParameters)
{
	throw "ERROR: Unable to retrieve ADP Common Template parameters file. Terminating the script unsuccessfully."
}
#endregion

#region - Control Routine

#region - Create new a dataset in Azure Data Factory
foreach ($dataset in $datasets)
{
	Write-Output "Publishing dataset $dataset"
	$Parameters = @{
		ResourceGroupName	  = $resourceGroupName
		DataFactoryName	      = $dataFactoryName
		File				  = "$sourceFilesPath\$dataset.json"
	}
	New-AzureRmDataFactoryDataset @Parameters -Force
}
#endregion

#endregion