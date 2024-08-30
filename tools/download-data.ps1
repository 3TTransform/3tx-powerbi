<#
.SYNOPSIS
    Download parquet data files from the 3tx platform

.DESCRIPTION
    This script uses your data key and organisation ID to fetch parquet files for processing.

.PARAMETER organisationId
    The organisation ID.

.PARAMETER dataKey
    The data key.

.PARAMETER environment
    The environment to download from. Defaults to production. Can be either production or uat.

.EXAMPLE
    .\download-data.ps1 -organisationId "fe32b459-6c83-4aab-825e-af94c0861e09" -dataKey "78d7da12-a61e-4bd3-8f3d-d7209b027dc9"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$organisationId,
    [Parameter(Mandatory=$true)]
    [string]$dataKey,
    [Parameter(Mandatory=$false)]
    [string]$environment = "production"
)

$headers = @{}
try {
    $apiBaseUrl = if ($environment -eq "production") {
        'https://api.3tplatform.com/v2'
    } elseif ($environment -eq "uat") {
        'https://uat.3tplatform.com/v2'
    } else {
        throw "Invalid environment: $environment. Must be 'production' or 'uat'."
    }
    $bucket = 'bronze'
    $fileTypes = @("workforce", "bookings", "attestations", "requirements", "activities")

    foreach ($fileType in $fileTypes) {
        $fileKey = "$organisationId/$organisationId" + "_$fileType.parquet"
        $reqUrl = "$apiBaseUrl/data/sign-download-url?bucket=$bucket&fileKey=$fileKey&apiKey=$dataKey"
        
        try {
            $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers
            $signedUrl = $response.url
            
            if ($signedUrl) {
                $outputFile = ".\$organisationId" + "_$fileType.parquet"
                Invoke-WebRequest -Uri $signedUrl -OutFile $outputFile
                Write-Output "File downloaded successfully: $outputFile"
            } else {
                Write-Error "Failed to obtain signed URL for $fileType"
            }
        } catch {
            Write-Error "An error occurred while downloading the $fileType file: $_"
        }
    }
} catch {
    Write-Error "An error occurred: $_"
} finally {
    Write-Output "Script execution completed."
}