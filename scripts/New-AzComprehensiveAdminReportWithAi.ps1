<#
.SYNOPSIS
    Pattern B entry point: generate comprehensive-report.html through an AI API.

.DESCRIPTION
    This wrapper keeps the public Pattern B name focused on API-based AI HTML
    generation while preserving compatibility with the existing implementation.
#>
[CmdletBinding()]
param(
    [string]$ResourcesJson = (Join-Path $PSScriptRoot '..\output\resources.json'),
    [string]$RbacJson      = (Join-Path $PSScriptRoot '..\output\rbac.json'),
    [string]$NsgJson       = (Join-Path $PSScriptRoot '..\output\nsg-rules.json'),
    [string]$DefenderJson  = (Join-Path $PSScriptRoot '..\output\defender-recommendations.json'),
    [string]$AdvisorJson   = (Join-Path $PSScriptRoot '..\output\advisor-recommendations.json'),
    [string]$PromptFile    = (Join-Path $PSScriptRoot '..\.github\prompts\azure-comprehensive-report.prompt.md'),
    [string]$OutputPath    = (Join-Path $PSScriptRoot '..\output\comprehensive-report.html'),
    [string]$EvidencePath  = (Join-Path $PSScriptRoot '..\output\report-evidence.json'),
    [string]$ApiEndpoint   = $(if ($env:AI_REPORT_API_ENDPOINT) { $env:AI_REPORT_API_ENDPOINT } else { 'https://models.inference.ai.azure.com/chat/completions' }),
    [string]$Model         = $(if ($env:AI_REPORT_MODEL) { $env:AI_REPORT_MODEL } else { 'gpt-4o-mini' }),
    [switch]$FailOnError
)

$implementation = Join-Path $PSScriptRoot 'New-AzComprehensiveAdminReportWithAgent.ps1'

$arguments = @{
    ResourcesJson = $ResourcesJson
    RbacJson = $RbacJson
    NsgJson = $NsgJson
    DefenderJson = $DefenderJson
    AdvisorJson = $AdvisorJson
    PromptFile = $PromptFile
    OutputPath = $OutputPath
    EvidencePath = $EvidencePath
    ApiEndpoint = $ApiEndpoint
    Model = $Model
}

if ($FailOnError) {
    & $implementation @arguments -FailOnError
} else {
    & $implementation @arguments
}