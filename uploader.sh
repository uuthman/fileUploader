#!/bin/bash

flag_r=false
flag_b=false

default_region=""


#Parse the options
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

# Check if a file exists in the bucket
check_if_file_exists_in_bucket() {
  local bucket_name="$1"
  local file_path="$2"

  aws s3 ls "s3://$bucket_name/$file_path" >/dev/null 2>&1

  return $?
}


# Give users different options to handle file
user_choice_for_file_handling() {
  local bucket_name="$1"
  local file_path="$2"

  echo "File '$file_path' already exists in S3 bucket '$bucket_name'."
    echo "Choose an option:"
    echo "1. Overwrite existing file"
    echo "2. Rename new file"
    echo "3. Skip and keep both"

    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1)
          # Option 1: Overwrite existing file
          aws s3 cp "$file_path" "s3://$bucket_name/$file_path" --acl bucket-owner-full-control --overwrite
          ;;
        2)
          # Option 2: Rename new file
          read -p "Enter new file name: " new_file_name
          aws s3 cp "$file_path" "s3://$bucket_name/$new_file_name" --acl bucket-owner-full-control
          ;;
        3)
          # Option 3: Skip and keep both
          echo "Skipping '$file_path'."
          ;;
        *)
          echo "Invalid choice. Exiting."
          exit 1
          ;;
      esac


}

#Validate the name of bucket to ensure it follows the s3 bucket naming
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

#Upload file
fileUploader() {

  #Validate if file exists
  if ! [ -f "$filePath" ];
   then
     echo "error: file not found"
     exit 1
  fi

  #Validate if the -b was passed
  if ! $flag_b;
  then
    echo "-b flag was not passed"
    exit 1
  fi

  #Validate name of the bucket
  validate_s3_bucket_name "$bucketName"



  #Check if bucket exists
  if ! aws s3 ls "s3://$bucketName" >/dev/null 2>&1;
  then
    #Check if a -r was passed
    if $flag_r;
    then
      default_region="$region"
    fi

    #
    if [ -z "$default_region" ]; then
        default_region="us-east-1"  # Default fallback region
    fi

      #Create a new bucket
      aws s3 mb s3://"$bucketName" --region "$default_region"
  fi


  #Check if file exists
  if check_if_file_exists_in_bucket "$bucketName" "$filePath"
  then
    #Give user choice for handling the file
    user_choice_for_file_handling "$bucketName" "$filePath"
  else
    #upload the file to the bucket
    upload_output=$(aws s3 cp "$filePath" s3://"$bucketName"/ 2>&1)
    upload_status=$?

    if [ $upload_status -eq 0 ]; then
        echo "Upload successful!"
    else
        echo "Upload failed: $upload_output."
    exit 3
    fi
  fi
}

#Initialize
fileUploader


