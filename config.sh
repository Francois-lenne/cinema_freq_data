# create a secret for the cinema_key


## Create a secret for the cinema_key

aws secretsmanager create-secret --name cinema_key --secret-string '{"cinema_key":"my_super_secret_key"}'


## check the secret

aws secretsmanager get-secret-value --secret-id cinema_key


aws lambda create-function \
    --function-name Lambdacinema \
    --runtime python3.10 \
    --role arn:aws:iam::123456789012:role/execution_role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://lambda_deployment.zip
