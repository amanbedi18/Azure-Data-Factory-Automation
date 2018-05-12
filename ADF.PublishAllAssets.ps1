<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
				
		File:		ADF.PublishAllAssets.ps1
		
		Purpose:	Azure Data Factory - Azure Deployment Automation Script
		
		Version: 	1.0.0.4 - 12th October 2017 - Release Deployment Team
		==============================================================================================

	.SYNOPSIS
		Azure Data Factory - Azure Deployment Automation Script
	
	.DESCRIPTION
		Azure Data Factory - Azure Deployment Automation Script
				
		Deployment steps of the script are outlined below.
		1) Login to an Azure Account 
		2) run Remove-ADF.AllAssets.ps1
		3) run New-ADF.LinkedServicesDeployment.ps1
		4) run New-ADF.DatasetsDeployment.ps1
		5) run New-ADF.PipelineDeployment.ps1
		    
	.PARAMETER env 
        Specify the environment name like dev, prod, uat'   
        Default  = "Dev"
	
	.PARAMETER sourceFilesPath
		Specify the location of source files
		Default = "F:\Source Code\dev\ADP\ADP.DataFactory"
	
	.PARAMETER templateFilePath
		Specify the location of template file
		Default = "F:\Source Code\dev\ADP\ADP.DataFactory"
	
	.PARAMETER deploymentFolderPath
		Specify the location of deployment folder
		Default = "F:\Source Code\Deployment Temp"
	
	.PARAMETER SubscriptionName 
        Speccify the Subscription Name
		Default = "Microsoft ADP Development"
		
	.PARAMETER MLFileName
	Specify the location of machine learning experiments name file
	
	.EXAMPLE
		Default:
        C:\PS> ADF.PublishAllAssets.ps1
        
        Custom:
        C:\PS> ADF.PublishAllAssets.ps1 -env <"env"> `
            -sourceFilesPath <"sourceFilesPath"> `
            -templateFilePath <"templateFilePath"> `
			-deploymentFolderPath <"deploymentFolderPath"> `
			-MLFileName <"MLFileName">
#>

#region - Global Variables
param
(
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[string]$env = "localdev",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[string]$sourceFilesPath = "C:Source\ADP\ADP.DataFactory",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[string]$templateFilePath = "C:\Source\ADP\ADP.DevOps\Templates\",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[string]$deploymentFolderPath = "C:\Source\ADP\ADP.DevOps\TestLocation",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[String]$MLFileName = "AMLExperiments.json",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[String]$ClientId = "{The app client Id}",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[String]$resourceAppIdURI = "{The resource app id uri}",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[String]$TenantId = "{The tenant Id}",
	[Parameter(ParameterSetName = 'Customize', Mandatory = $false)]
	[String]$ClientKey = "{The client Key}"
)

#remove the 2 lines below as well as azure login code in production
$templateParametersFile = "$templateFilePath" + "ADF.Parameters_$env.json"
Get-Content -Path $templateParametersFile -Raw

#endregion

#region - Control Routine

#region - Azure Account login

try
{
	$secpasswd = ConvertTo-SecureString $ClientKey -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($ClientId, $secpasswd)
	Login-AzureRmAccount -ServicePrincipal -Tenant $TenantId -Credential $mycreds
}
catch
{
    Write-Host "Login failed or there are no subscriptions available with your account." -ForegroundColor Red
    Write-Host "Please logout using the command azure Remove-AzureAccount and try again." -ForegroundColor Red
    Exit
}
#endregion

#region - Deploy ADF assets
.$PSScriptRoot\Remove-ADF.AllAssets.ps1 -env $env -templateFilePath $templateFilePath
.$PSScriptRoot\New-ADF.LinkedServicesDeployment.ps1 -env $env -sourceFilesPath $sourceFilesPath -templateFilePath $templateFilePath -deploymentFolderPath $deploymentFolderPath -MLFileName $MLFileName
.$PSScriptRoot\New-ADF.DatasetsDeployment.ps1 -env $env -sourceFilesPath $sourceFilesPath -templateFilePath $templateFilePath -deploymentFolderPath $deploymentFolderPath
.$PSScriptRoot\New-ADF.PipelineDeployment.ps1 -env $env -sourceFilesPath $sourceFilesPath -templateFilePath $templateFilePath -deploymentFolderPath $deploymentFolderPath
#endregion

#endregion