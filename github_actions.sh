#!/bin/bash

# Retrieve AWS Account ID automatically
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Set these variables before running the script
GITHUB_OWNER="YOUR_GITHUB_OWNER"
GITHUB_REPO="YOUR_REPOSITORY"
CODEBUILD_PROJECT_NAME="YOUR_CODEBUILD_PROJECT_NAME"
REGION=$(aws configure get region)

# Verify AWS Account ID was retrieved
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: Could not retrieve AWS Account ID. Please check your AWS CLI configuration."
    exit 1
fi

# Create CodeBuild Policy JSON
cat > codebuild-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:StartBuild"
            ],
            "Resource": "arn:aws:codebuild:${REGION}:${AWS_ACCOUNT_ID}:project/${CODEBUILD_PROJECT_NAME}"
        }
    ]
}
EOF

# Create Trust Relationship JSON
cat > trust-relationship.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

# Default to us-east-1 if no region is set
REGION=${REGION:-us-east-1}

# Create IAM Policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name GitHubActionsCodeBuildAccess \
    --policy-document file://codebuild-policy.json \
    --query 'Policy.Arn' \
    --output text)

# Create IAM Role
aws iam create-role \
    --role-name GitHubActionsCodeBuildRole \
    --assume-role-policy-document file://trust-relationship.json

# Attach Policy to Role
aws iam attach-role-policy \
    --role-name GitHubActionsCodeBuildRole \
    --policy-arn "$POLICY_ARN"

# Print out the role ARN for use in GitHub Actions
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "IAM Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsCodeBuildRole"
echo "Region: ${REGION}"

# Cleanup temporary files
rm codebuild-policy.json trust-relationship.json
