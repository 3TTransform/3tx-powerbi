#!/bin/bash

# Download parquet data files from the 3tx platform
#
# This script uses your data key and organisation ID to fetch parquet files for processing.
#
# The environment defaults to production. Can be either production or uat.
#
# Usage: ./download-data.sh -o <organisationId> -k <dataKey> [-e <environment>]
#
# Example: ./download-data.sh -o "fe32b459-6c83-4aab-825e-af94c0861e09" -k "78d7da12-a61e-4bd3-8f3d-d7209b027dc9" -e "uat"

# Default values
environment="production"

function csv_to_parquet() {
    file_path="$1"
    duckdb -c "COPY (SELECT * FROM read_csv_auto('$file_path')) TO '${file_path%.*}.parquet' (FORMAT PARQUET);"
}

function parquet_to_csv() {
    file_path="$1"
    duckdb -c "COPY (SELECT * FROM '$file_path') TO '${file_path%.*}.csv' (HEADER, FORMAT 'csv');"
}

# Parse command line arguments
while getopts ":o:k:e:" opt; do
  case $opt in
    o) organisationId="$OPTARG"
    ;;
    k) dataKey="$OPTARG"
    ;;
    e) environment="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Check if required parameters are provided
if [ -z "$organisationId" ] || [ -z "$dataKey" ]; then
  echo "Error: organisationId and dataKey are required."
  echo "Usage: $0 -o <organisationId> -k <dataKey> [-e <environment>]"
  exit 1
fi

# Set API base URL based on environment
if [ "$environment" = "production" ]; then
  apiBaseUrl="https://api.3tplatform.com/v2"
elif [ "$environment" = "uat" ]; then
  apiBaseUrl="https://uat.3tplatform.com/v2"
else
  echo "Error: Invalid environment: $environment. Must be 'production' or 'uat'."
  exit 1
fi

bucket="bronze"
fileTypes=("workforce" "bookings" "attestations" "requirements" "activities")

for fileType in "${fileTypes[@]}"; do
  fileKey="$organisationId/${organisationId}_${fileType}.parquet"
  reqUrl="${apiBaseUrl}/data/sign-download-url?bucket=${bucket}&fileKey=${fileKey}&apiKey=${dataKey}"
  
  response=$(curl -s -X GET "$reqUrl")
  signedUrl=$(echo "$response" | jq -r '.url')
  
  if [ -n "$signedUrl" ] && [ "$signedUrl" != "null" ]; then
    outputFile="./${organisationId}_${fileType}.parquet"
    if curl -s -o "$outputFile" "$signedUrl"; then
      echo "File downloaded successfully: $outputFile"
      parquet_to_csv "$outputFile"
      echo "Converted to CSV: ${outputFile%.*}.csv"
    else
      echo "Error: Failed to download file for $fileType" >&2
    fi
  else
    echo "Error: Failed to obtain signed URL for $fileType" >&2
  fi
done

echo "Script execution completed."
