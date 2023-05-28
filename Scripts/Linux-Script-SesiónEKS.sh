#!/bin/bash

# Solicitar el ID de la cuenta
echo -n "Ingrese el ID de la cuenta a la cual desea conectarse: "
read account_id

# Construir el comando1 con el ID de cuenta actualizado
comando1="aws sts assume-role --role-arn \"arn:aws:iam::${account_id}:role/titan-pipeline\" --role-session-name titan-pipeline"

echo "El comando1 a ejecutar es: $comando1"

# Ejecutar comando1 y capturar la salida
output=$(eval "$comando1")

# Verificar si el comando1 se ejecutó correctamente
if [ $? -eq 0 ]; then
    # Obtener los valores de AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN del resultado de comando1
    aws_access_key_id=$(echo "$output" | jq -r '.Credentials.AccessKeyId')
    aws_secret_access_key=$(echo "$output" | jq -r '.Credentials.SecretAccessKey')
    aws_session_token=$(echo "$output" | jq -r '.Credentials.SessionToken')

    # Establecer las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN
    export AWS_ACCESS_KEY_ID="$aws_access_key_id"
    export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key"
    export AWS_SESSION_TOKEN="$aws_session_token"

    echo "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN se han establecido correctamente."

    # Solicitar el nombre del cluster
    echo -n "Ingrese el nombre del cluster al que desea conectarse: "
    read cluster_name

    # Construir el comando2 con el nombre del cluster actualizado
    comando2="aws eks update-kubeconfig --name \"$cluster_name\""

    echo "El comando2 a ejecutar es: $comando2"

    # Ejecutar comando2
    eval "$comando2"

    echo "El comando aws eks update-kubeconfig se ha ejecutado correctamente."
else
    echo "Hubo un error al ejecutar el comando aws sts assume-role. Por favor, verifique el ID de la cuenta y vuelva a intentarlo."
fi