#!/bin/bash

set -e

# Load environment variables from .env.users
if [ ! -f .env.users ]; then
    echo "Error: .env.users file not found"
    echo "Copy .env.users.example to .env.users and configure it"
    exit 1
fi

source .env.users

# Get AWS Region from Terraform if not set
if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
fi

# Get Cognito User Pool ID from Terraform if not set
if [ -z "$COGNITO_USER_POOL_ID" ]; then
    COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
    if [ -z "$COGNITO_USER_POOL_ID" ]; then
        echo "Error: Could not get Cognito User Pool ID from Terraform"
        echo "Run 'terraform apply' first or set COGNITO_USER_POOL_ID in .env.users"
        exit 1
    fi
fi

echo "Using Region: $AWS_REGION"
echo "Using User Pool ID: $COGNITO_USER_POOL_ID"

# Validate required variables
if [ -z "$USERS" ]; then
    echo "Error: USERS variable is required in .env.users"
    exit 1
fi

# Split users by comma and create each one
IFS=',' read -ra USER_ARRAY <<< "$USERS"

# Initialize created_users.txt file with header
CREATED_USERS_FILE="created_users.txt"
echo "Created Users - $(date '+%Y-%m-%d %H:%M:%S')" > "$CREATED_USERS_FILE"
echo "========================================" >> "$CREATED_USERS_FILE"
echo "" >> "$CREATED_USERS_FILE"

echo ""
for email in "${USER_ARRAY[@]}"; do
    email=$(echo "$email" | xargs) # Trim whitespace
    
    # Generate unique password for each user
    if [ -z "$TEMP_PASSWORD" ]; then
        USER_PASSWORD="Temp$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-10)!"
    else
        USER_PASSWORD="$TEMP_PASSWORD"
    fi
    
    echo "Creating user: $email"
    
    # Temporarily disable exit on error to handle user existence check
    set +e
    
    # Try to create user and capture error output
    ERROR_OUTPUT=$(aws cognito-idp admin-create-user \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --username "$email" \
        --user-attributes Name=email,Value="$email" Name=email_verified,Value=true \
        --temporary-password "$USER_PASSWORD" \
        --region "$AWS_REGION" \
        --message-action SUPPRESS 2>&1)
    CREATE_ERROR=$?
    
    # Re-enable exit on error
    set -e
    
    if [ $CREATE_ERROR -eq 0 ]; then
        # User created successfully
        echo "✓ User $email created with password: $USER_PASSWORD"
        echo "Email: $email" >> "$CREATED_USERS_FILE"
        echo "Password: $USER_PASSWORD" >> "$CREATED_USERS_FILE"
        echo "" >> "$CREATED_USERS_FILE"
    elif echo "$ERROR_OUTPUT" | grep -q "UsernameExistsException"; then
        # User already exists
        echo "⚠ User $email already exists"
        read -p "Do you want to reset the password for this user? (y/n): " RESET_CONFIRM
        if [[ "$RESET_CONFIRM" =~ ^[Yy]$ ]]; then
            set +e
            if aws cognito-idp admin-set-user-password \
                --user-pool-id "$COGNITO_USER_POOL_ID" \
                --username "$email" \
                --password "$USER_PASSWORD" \
                --permanent \
                --region "$AWS_REGION" > /dev/null 2>&1; then
                set -e
                echo "✓ Password reset for user $email: $USER_PASSWORD"
                echo "Email: $email (password reset)" >> "$CREATED_USERS_FILE"
                echo "Password: $USER_PASSWORD" >> "$CREATED_USERS_FILE"
                echo "" >> "$CREATED_USERS_FILE"
            else
                set -e
                echo "✗ Failed to reset password for user $email"
            fi
        else
            echo "Skipping password reset for user $email"
        fi
    else
        # Other error occurred - don't exit script, just report
        echo "✗ Failed to create user $email"
        echo "Error: $ERROR_OUTPUT"
    fi
    
    echo ""
done

echo "User creation complete!"
echo "Users will be prompted to change password on first login"
echo ""
echo "Created users and passwords saved to: $CREATED_USERS_FILE"
