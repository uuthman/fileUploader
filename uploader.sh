#!/bin/bash

flag_r=false
flag_b=false

default_region="us-east-1"

while getopts f:b:r: flag
  do
    case "$flag" in
    f)
     filePath=${OPTARG}
      ;;
    b)
      flag_b=true
      bucketName=${OPTARG}
      ;;
    r)
      flag_r=true
      region=${OPTARG}
      ;;
    *)
      echo "Invalid flag"
      ;;
    esac
  done


validate_s3_bucket_name() {
  bucket_name="$1"

  if [ ${#bucket_name} -lt 3 ] || [ ${#bucket_name} -gt  63 ]
  then
    echo "Invalid bucket name length (must be between 3 and 63 characters)." >&2
        exit 1
  fi

  if ! [[  "$bucket_name" =~ ^[a-z0-9][a-z0-9.-]+$ ]]
  then
      echo "Invalid bucket name format." >&2
      echo "Bucket name can only contain lowercase letters, numbers, hyphens, and dots." >&2
      echo "It must start with a lowercase letter or number." >&2
      exit 1
    fi


  if [[ "$bucket_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
  then
      echo "Invalid bucket name format (cannot be formatted as an IP address)." >&2
      exit 1
    fi
}

fileUploader() {

  if ! [ -f "$filePath" ];
   then
     echo "error: file not found"
     exit 1
  fi

  if ! $flag_b;
  then
    echo "-b flag was not passed"
    exit 1
  fi


  validate_s3_bucket_name "$bucketName"


  if ! aws s3 ls | grep -q "$bucketName"
  then
    if $flag_r;
    then
      default_region="$region"
    fi
      aws s3 mb s3://"$bucketName" --region "$default_region"
  else
    echo "found a file"
  fi

}

fileUploader


