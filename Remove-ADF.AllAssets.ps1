<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
				
		File:		Remove-ADF.AllAssets.ps1
		
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
		3) Remove datasets and pipelines present in template file
		    
	.PARAMETER env 
        Specify the environment name like dev, prod, uat'   
        	
	.PARAMETER templateFilePath
		Specify the location of template file
			
	.EXAMPLE
		Default:
            C:\PS> New-ADF.PipelineDeployment.ps1 -env <"env"> `
            -templateFilePath <"templateFilePath"> 
           
#>

#region - Global Variables
param
(
	[Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Specify the environment name like dev, prod, uat')]
	[String]$env,
	[Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Specify the location of template file')]
	[String]$templateFilePath
)

$templateParametersFile = "$templateFilePath" + "ADF.Parameters_$env.json"
$templateParameters = Get-Content -Path $templateParametersFile -Raw | ConvertFrom-JSON

if (-not $templateParameters)
{
	throw "ERROR: Unable to retrieve ADP Template parameters file. Terminating the script unsuccessfully."
}

$resourceGroupName = $templateParameters.parameters.resourceGroupName.value
$dataFactoryName = $templateParameters.parameters.dataFactoryName.value

$commonTemplateParametersFile = "$templateFilePath\ADF.Parameters.Common.json"
$commonTemplateParameters = Get-Content -Path $commonTemplateParametersFile -Raw | ConvertFrom-JSON

if (-not $commonTemplateParameters)
{
	throw "ERROR: Unable to retrieve ADP Common Template parameters file. Terminating the script unsuccessfully."
}
#endregion

#region - Control Routine

#region - Remove datasets and pipelines present in template file
$Parameters = @{
	ResourceGroupName	  = $resourceGroupName
	Name				  = $dataFactoryName
}
$adf = Get-AzureRmDataFactory @Parameters -ErrorAction Ignore

if ($adf -ne $null)
{
	$datasets = $commonTemplateParameters.parameters.datasets.value
	$pipelines = $commonTemplateParameters.parameters.pipelines.value
	$resourceGroupName = $templateParameters.parameters.resourceGroupName.value
	$dataFactoryName = $templateParameters.parameters.dataFactoryName.value
	
	foreach ($pipeline in $pipelines)
	{
		$Parameters = @{
			ResourceGroupName	  = $resourceGroupName
			DataFactoryName	      = $dataFactoryName
		}
		$existingPipelines = Get-AzureRmDataFactoryPipeline @Parameters
		
		foreach ($temp in $existingPipelines)
		{
			if ($temp.PipelineName -eq $pipeline)
			{
				Write-Output "Removing pipeline $pipeline"
				$Parameters = @{
					ResourceGroupName	  = $resourceGroupName
					DataFactoryName	      = $dataFactoryName
					Name				  = $pipeline
				}
				Remove-AzureRmDataFactoryPipeline @Parameters -Force
				break
			}
		}
	}
	
	foreach ($dataset in $datasets)
	{
		$Parameters = @{
			ResourceGroupName	  = $resourceGroupName
			DataFactoryName	      = $dataFactoryName
		}
		$existingDatasets = Get-AzureRmDataFactoryDataset @Parameters
		foreach ($temp in $existingDatasets)
		{
			if ($temp.DatasetName -eq $dataset)
			{
				Write-Output "Removing dataset $dataset"
				$Parameters = @{
					ResourceGroupName	  = $resourceGroupName
					DataFactoryName	      = $dataFactoryName
					Name				  = $dataset
				}
				Remove-AzureRmDataFactoryDataset @Parameters -Force
				break
			}
		}
	}
}
else
{
	throw "Adf is not provisioned, exiting without succesful execution!"
}
#endregion

#endregion
