#!/bin/bash

# Charger les variables d'environnement
AWS_REGION=""
AWS_ACCOUNT_ID=""
GITHUB_REPO=""
GITHUB_USER=""
PROJECT_NAME=""

# Créer le rôle IAM pour CodeBuild
aws iam create-role \
    --role-name "${PROJECT_NAME}-CodeBuildRole" \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "codebuild.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'

# Attacher les politiques nécessaires
aws iam put-role-policy \
    --role-name "${PROJECT_NAME}-CodeBuildRole" \
    --policy-name "${PROJECT_NAME}-CodeBuildPolicy" \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ecr:*",
                    "lambda:UpdateFunctionCode",
                    "logs:*"
                ],
                "Resource": "*"
            }
        ]
    }'

# Créer le projet CodeBuild
aws codebuild create-project \
    --name "${PROJECT_NAME}-build" \
    --source type=GITHUB,location="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" \
    --artifacts type=NO_ARTIFACTS \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux2-x86_64-standard:4.0,computeType=BUILD_GENERAL1_SMALL,privilegedMode=true \
    --service-role "${PROJECT_NAME}-CodeBuildRole" \
    --cache type=NO_CACHE \
    --region ${AWS_REGION}

# Configurer les alertes CloudWatch
aws cloudwatch put-metric-alarm \
    --alarm-name "${PROJECT_NAME}-BuildErrors" \
    --alarm-description "Alerte si le build échoue" \
    --metric-name FailedBuilds \
    --namespace AWS/CodeBuild \
    --dimensions Name=ProjectName,Value="${PROJECT_NAME}-build" \
    --statistic Sum \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1 \
    --comparison-operator GreaterThanThreshold \
    --region ${AWS_REGION}


# configur le déclenchement du build


# 1. Créer un Personal Access Token (PAT) sur GitHub
# Allez sur GitHub > Settings > Developer settings > Personal access tokens > Generate new token

# 2. Configurer la source GitHub dans CodeBuild


# Créer le déclencheur
aws codebuild create-webhook \
    --project-name "${PROJECT_NAME}-build" \
    --filter-groups '[[
        {
            "type": "EVENT",
            "pattern": "PUSH"
        },
        {
            "type": "HEAD_REF",
            "pattern": "^refs/heads/main$"
        }
    ]]' \
    --region ${AWS_REGION}