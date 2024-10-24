# create a secret for the cinema_key


## Create a secret for the cinema_key

aws secretsmanager create-secret --name cinema_key --secret-string '{"cinema_key":"my_super_secret_key"}'


## check the secret

aws secretsmanager get-secret-value --secret-id cinema_key

