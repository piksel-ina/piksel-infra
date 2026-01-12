#!/bin/bash

# Configuration
PROFILE="dev-piksel"
REGION="ap-southeast-3"
BUCKET_NAME="terraform-backup-dev-piksel"
RESTORE_DIR="tf_backup"

# Files to backup/restore
FILES=(
    "terraform.tfstate"
    "terraform.tfstate.backup"
    ".terraform.lock.hcl"
)

create_s3() {
    echo "Creating S3 bucket for Terraform state backup..."
    echo "Bucket name: $BUCKET_NAME"
    echo "Region: $REGION"
    echo ""

    # Create bucket
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" \
        --profile "$PROFILE"

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create bucket"
        exit 1
    fi

    echo "✓ Bucket created"

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled \
        --profile "$PROFILE"

    echo "✓ Versioning enabled"

    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile "$PROFILE"

    echo "✓ Public access blocked"
    echo ""
    echo "Setup complete!"
}

# Upload to S3
run_backup() {
    echo "Starting Terraform state backup to S3..."
    echo "Bucket: $BUCKET_NAME"
    echo ""

    # Backup each file
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "Uploading: $file"
            aws s3 cp "$file" "s3://$BUCKET_NAME/$file" \
                --region "$REGION" \
                --profile "$PROFILE"

            if [ $? -eq 0 ]; then
                echo "✓ $file backed up successfully"
            else
                echo "✗ Failed to backup $file"
            fi
        else
            echo "- Skipping $file (not found)"
        fi
    done

    echo ""
    echo "Backup complete!"
}

# Restore from S3
get_backup() {
    echo "Starting Terraform state restore from S3..."
    echo "Bucket: $BUCKET_NAME"
    echo "Restore directory: $RESTORE_DIR"
    echo ""

    # Create restore directory
    mkdir -p "$RESTORE_DIR"
    echo "✓ Created restore directory: $RESTORE_DIR"
    echo ""

    # Restore each file
    for file in "${FILES[@]}"; do
        echo "Downloading: $file"
        aws s3 cp "s3://$BUCKET_NAME/$file" "$RESTORE_DIR/$file" \
            --region "$REGION" \
            --profile "$PROFILE"

        if [ $? -eq 0 ]; then
            echo "✓ $file restored to $RESTORE_DIR/"
        else
            echo "✗ Failed to restore $file (may not exist in bucket)"
        fi
    done

    echo ""
    echo "Restore complete!"
    echo ""
    echo "Files are in: $RESTORE_DIR/"
    echo "Review the files before manually moving them to your Terraform directory"
}

# Main script logic
case "$1" in
    create-s3)
        create_s3
        ;;
    run)
        run_backup
        ;;
    get)
        get_backup
        ;;
    *)
        echo "Invalid command. Use: create-s3, run, or get"
        exit 1
        ;;
esac
