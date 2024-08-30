<#
.SYNOPSIS
    Download parquet data files from the 3tx platform

.DESCRIPTION
    This script uses your data key and organisation ID to fetch parquet files for processing.

.PARAMETER organisationId
    The organisation ID.

.PARAMETER dataKey
    The data key.

.EXAMPLE
    .\download-data.ps1 -organisationId "fe32b459-6c83-4aab-825e-af94c0861e09" -dataKey "78d7da12-a61e-4bd3-8f3d-d7209b027dc9"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$organisationId,
    [Parameter(Mandatory=$true)]
    [string]$dataKey
)

try {
    Write-Output "Hello, $organisationId and $dataKey"
} catch {
    Write-Error "An error occurred: $_"
} finally {
    Write-Output "Script execution completed."
}