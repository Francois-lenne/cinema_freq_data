# Utiliser l'image de base AWS Lambda pour Python 3.10
FROM public.ecr.aws/lambda/python:3.10

# Copier le code source de la fonction Lambda
COPY src/main.py ${LAMBDA_TASK_ROOT}/lambda_function.py

# Copier le fichier requirements.txt et installer les dépendances
COPY src/requirements.txt .
RUN pip install -r requirements.txt -t ${LAMBDA_TASK_ROOT}

# Commande par défaut pour exécuter la fonction Lambda
CMD ["lambda_function.lambda_handler"]