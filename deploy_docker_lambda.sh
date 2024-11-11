REGION=
ACCOUNT_ID=
ROLE=
EVENT_NAME=
FUNCTION_NAME=
REPOSITORY_NAME=


# config IAM

# 1. Créer un rôle IAM pour la fonction Lambda

# les accès mise en place sont : S3, lambda , secret manager, ECRLAMBDAACESSPOLICY


# I) créer un container lambda

# 1. Créer un repository ECR

aws ecr create-repository --repository-name $REPOSITORY_NAME --region $REGION

# 2. Construire l'image Docker

docker build -t lambdacinema .

# 3. Tag l'image Docker

docker tag lambdacinema:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:latest

# 4. Authentification Docker

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 5. Push l'image Docker

docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:latest


# III) créer une fonction lambda


# 1. Créer la fonction Lambda

aws lambda create-function \
    --function-name FUNCTION_NAME \
    --package-type Image \
    --code ImageUri=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:latest \
    --role arn:aws:iam::123456789012:role/execution_role \
    --region $REGION



# 2. Configurer la fonction Lambda (optionel)
aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --timeout 15 \
    --memory-size 512 \
    --region $REGION



# 3. donner les droits à la fonction lambda pour accéder au secret cinema_key et au repoistory 


cat << EOF > ecr_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetAuthorizationToken",
                "ecr:ListImages"
            ],
            "Resource": [
                "arn:aws:ecr:$REGION:$ACCOUNT_ID:repository/$REPOSITORY_NAME",
                "arn:aws:ecr:$REGION:$ACCOUNT_ID:repository/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}
EOF



aws iam put-role-policy     --role-name $ROLE     --policy-name ECRLambdaAccessPolicy     --policy-document file://ecr_lambda_policy.json


#### Secrets Manager


cat << 'EOF' > secrets_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:$REGION:$ACCOUNT_ID:secret:cinema_key*"
        }
    ]
}
EOF


aws iam put-role-policy \
    --role-name $ROLE \
    --policy-name SecretsManagerAccess \
    --policy-document file://secrets_policy.json





# 4. tester la fonction lambda


aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    --region $REGION \
    output.json


# III) créer un déclencheur pour le container lambda




# 1. Créer la règle EventBridge avec une expression cron
aws events put-rule \
    --name "$EVENT_NAME" \
    --schedule-expression "cron(0 8 * * ? *)" \
    --description "Déclenche la fonction $FUNCTION_NAME tous les jours à 8h00" \
    --region $REGION

# 2. Ajouter la permission au Lambda
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id $EVENT_NAME \
    --action 'lambda:InvokeFunction' \
    --principal events.amazonaws.com \
    --source-arn arn:aws:events:$REGION::rule/$EVENT_NAME \
    --region $REGION

# 3. Configurer la cible de la règle
aws events put-targets \
    --rule $EVENT_NAME \
    --targets "Id"="1","Arn"="arn:aws:lambda:$REGION::function:$FUNCTION_NAME" \
    --region $REGION