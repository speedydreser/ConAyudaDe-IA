### Solicitar el ID de la cuenta
$account_id = Read-Host "Ingrese el ID de la cuenta a la cual desea conectarse"

# Construir el comando1 con el ID de cuenta actualizado
$comando1 = "aws sts assume-role --role-arn ""arn:aws:iam::${account_id}:role/titan-pipeline"" --role-session-name titan-pipeline"

Write-Host "El comando1 a ejecutar es:"
Write-Host $comando1

# Ejecutar comando1 y capturar la salida
$output = Invoke-Expression $comando1

# Verificar si el comando1 se ejecutó correctamente
if ($LASTEXITCODE -eq 0) {
    # Obtener los valores de AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN del resultado de comando1
    $aws_access_key_id = ($output | ConvertFrom-Json).Credentials.AccessKeyId
    $aws_secret_access_key = ($output | ConvertFrom-Json).Credentials.SecretAccessKey
    $aws_session_token = ($output | ConvertFrom-Json).Credentials.SessionToken

    # Establecer las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN
    $env:AWS_ACCESS_KEY_ID = $aws_access_key_id
    $env:AWS_SECRET_ACCESS_KEY = $aws_secret_access_key
    $env:AWS_SESSION_TOKEN = $aws_session_token

    Write-Host "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_SESSION_TOKEN se han establecido correctamente."

    # Solicitar el nombre del cluster
    $cluster_name = Read-Host "Ingrese el nombre del cluster al que desea conectarse"

    # Construir el comando2 con el nombre del cluster actualizado
    $comando2 = "aws eks update-kubeconfig --name ""$cluster_name"""

    Write-Host "El comando2 a ejecutar es:"
    Write-Host $comando2

    # Ejecutar comando2
    Invoke-Expression $comando2

    Write-Host "El comando aws eks update-kubeconfig se ha ejecutado correctamente."
}
else {
    Write-Host "Hubo un error al ejecutar el comando aws sts assume-role. Por favor, verifique el ID de la cuenta y vuelva a intentarlo."
}
