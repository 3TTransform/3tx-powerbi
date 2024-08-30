<#
.SYNOPSIS
    Download parquet data files from the 3tx platform and optionally convert them to CSV

.DESCRIPTION
    This script uses your data key and organisation ID to fetch parquet files for processing.
    It can optionally convert the downloaded parquet files to CSV format using DuckDB.

.PARAMETER organisationId
    The organisation ID.

.PARAMETER dataKey
    The data key.

.PARAMETER environment
    The environment to download from. Defaults to production. Can be either production or uat.

.PARAMETER convertToCsv
    If specified, converts downloaded parquet files to CSV format.

.EXAMPLE
    .\download-data.ps1 -organisationId "fe32b459-6c83-4aab-825e-af94c0861e09" -dataKey "78d7da12-a61e-4bd3-8f3d-d7209b027dc9"

.EXAMPLE
    .\download-data.ps1 -organisationId "fe32b459-6c83-4aab-825e-af94c0861e09" -dataKey "78d7da12-a61e-4bd3-8f3d-d7209b027dc9" -convertToCsv
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$organisationId,
    [Parameter(Mandatory=$true)]
    [string]$dataKey,
    [Parameter(Mandatory=$false)]
    [string]$environment = "production",
    [Parameter(Mandatory=$false)]
    [switch]$convertToCsv
)

function Convert-ParquetToCsv {
    param (
        [string]$filePath
    )
    # Remove leading ./ from the filePath if it exists
    $filePath = $filePath -replace '^\.[\\/]', ''
    Write-Output "Starting conversion of $filePath to CSV"
    $outputPath = [System.IO.Path]::ChangeExtension($filePath, "csv")
    Write-Output "Output path will be: $outputPath"
    
    try {
        duckdb -c "COPY (SELECT * FROM read_parquet('$filePath')) TO '$outputPath' (HEADER, FORMAT 'csv');"
        
        if (Test-Path $outputPath) {
            Write-Output "CSV file successfully created: $outputPath"
        } else {
            throw "CSV file was not created at expected path: $outputPath"
        }
    } catch {
        throw "An error occurred during conversion: $_"
    }
}

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
                if ($convertToCsv) {
                    Convert-ParquetToCsv -filePath $outputFile
                }
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