#!/bin/bash
set -euo pipefail

print_usage () {
  cat << EOF
Usage: $0 <arg>
    Possible args:
    PRD    Switch to production read-only access role.
    STG    Switch back to original staging role.
EOF
}

if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

for arg in "$@"; do
case "$arg" in

  STG)
    if [ -f ~/.aws/backup_credentials ]; then 
      mv ~/.aws/backup_credentials ~/.aws/credentials
      echo "In staging role."
      exit 0
    else
      echo "Cannot switch back to staging role. Please restart the app."
      exit 0
    fi
    ;;
  
  PRD)
    if grep -q "aws_session_token" ~/.aws/credentials; then
      echo "Currently in production role. Please first switch back to staging role."
      exit 0
    
    else
      access_key_id=$(grep "aws_access_key_id" ~/.aws/credentials)
      secret_access_key=$(grep "aws_secret_access_key" ~/.aws/credentials)

      echo [default] >> ~/.aws/backup_credentials
      echo $access_key_id >> ~/.aws/backup_credentials
      echo $secret_access_key >> ~/.aws/backup_credentials

      echo "Getting production credentials..."
      role_creds=$(aws sts assume-role --role-arn "{}" --role-session-name "{}")

      echo "Placing into .env file..."
      rm ~/.aws/credentials
      touch ~/.aws/credentials
      
      echo [default] >> ~/.aws/credentials
      echo aws_access_key_id = $(echo $role_creds | jq --raw-output '.Credentials.AccessKeyId') >> ~/.aws/credentials
      echo aws_secret_access_key = $(echo $role_creds | jq --raw-output '.Credentials.SecretAccessKey') >> ~/.aws/credentials
      echo aws_session_token = $(echo $role_creds | jq --raw-output '.Credentials.SessionToken') >> ~/.aws/credentials

      echo "In production role."
      exit 0
    fi
    ;;
  *)
    print_usage
    exit 1
    ;;
  esac
done
