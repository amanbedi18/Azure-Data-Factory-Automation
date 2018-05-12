<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
				
		File:		New-ADF.PipelineDeployment.ps1
		
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
		3) Create new Azure Data Factory Pipeline
		    
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
            C:\PS> New-ADF.PipelineDeployment.ps1 -env <"env"> `
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
$dataFactoryHubName = $templateParameters.parameters.dataFactoryHubName.value
$resourceGroupName = $templateParameters.parameters.resourceGroupName.value

$commonTemplateParameters = Get-Content -Path $commonTemplateParametersFile -Raw | ConvertFrom-JSON
if (-not $commonTemplateParameters)
{
	throw "ERROR: Unable to retrieve ADP Common Template parameters file. Terminating the script unsuccessfully."
}

$pipelines = $commonTemplateParameters.parameters.pipelines.value
$pipelineStartTime = $commonTemplateParameters.parameters.pipelineStartTime.value
$pipelineEndTime = $commonTemplateParameters.parameters.pipelineEndTime.value
#endregion

#region - Control Routine

#region - Create new a Pipeline in Azure Data Factory
foreach ($pipelineName in $pipelines)
{
	Write-Output "Publishing pipeline $pipelineName"
	$file = "$sourceFilesPath\$pipelineName.json"
	$pipeline = Get-Content -Path $file -Raw | ConvertFrom-JSON
	$pipeline.properties.start = $pipelineStartTime
	$pipeline.properties.end = $pipelineEndTime
	if ($pipeline.properties.hubName)
	{
		$pipeline.properties.hubName = $dataFactoryHubName
	}
	
	$destinationPath = "$deploymentFolderPath\$pipeline-SliceAdjusted.json"
	
	$pipeline | ConvertTo-JSON -Depth 7 | Out-File -filepath $destinationPath -Force
	$Parameters = @{
		ResourceGroupName   = $ResourceGroupName
		DataFactoryName	    = $DataFactoryName
		File			    = $destinationPath
	}
	New-AzureRmDataFactoryPipeline @Parameters -Force
}
#endregion

#endregion
