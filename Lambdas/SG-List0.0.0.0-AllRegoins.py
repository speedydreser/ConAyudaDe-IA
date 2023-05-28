import os
import boto3
import csv
import tempfile

def lambda_handler(event, context):
    # Obtener la información de la cuenta de AWS
    sts = boto3.client('sts')
    account_id = sts.get_caller_identity().get('Account')
    
    # Nombre del bucket
    bucket_name = f"{account_id}-bucket-sgporrevisar"
    
    # Verificar si el bucket existe
    s3 = boto3.client('s3')
    bucket_exists = False
    try:
        s3.head_bucket(Bucket=bucket_name)
        bucket_exists = True
    except:
        pass
    
    # Si el bucket no existe, crearlo
    if not bucket_exists:
        s3.create_bucket(Bucket=bucket_name)
        s3.put_bucket_tagging(
            Bucket=bucket_name,
            Tagging={
                'TagSet': [
                    {
                        'Key': 'Project',
                        'Value': 'general'
                    }
                ]
            }
        )
    
    # Obtener los grupos de seguridad y sus detalles de todas las regiones de AWS
    regions = [region['RegionName'] for region in boto3.client('ec2').describe_regions()['Regions']]
    all_groups = []
    for region in regions:
        try:
            ec2 = boto3.client('ec2', region_name=region)
            response = ec2.describe_security_groups()

            instances = {}
            for reservation in ec2.describe_instances().get('Reservations', []):
                for instance in reservation.get('Instances', []):
                    for sg in instance.get('SecurityGroups', []):
                        if sg['GroupId'] not in instances:
                            instances[sg['GroupId']] = []
                        instances[sg['GroupId']].append(instance)

            for group in response['SecurityGroups']:
                for rule in group['IpPermissions']:
                    for ip_range in rule['IpRanges']:
                        if ip_range['CidrIp'] == '0.0.0.0/0':
                            group_id = group['GroupId']
                            group_name = group['GroupName']
                            ip_range = ip_range['CidrIp']
                            protocol = rule['IpProtocol']
                            from_port = rule.get('FromPort')
                            to_port = rule.get('ToPort')
                            used_by = None
                            used_by_id = None
                            for instance in instances.get(group_id, []):
                                used_by = instance['InstanceId']
                                used_by_id = instance.get('Tags', {}).get('Name')
                            all_groups.append({
                                'group_id': group_id,
                                'group_name': group_name,
                                'ip_range': ip_range,
                                'protocol': protocol,
                                'from_port': from_port,
                                'to_port': to_port,
                                'used_by': used_by,
                                'used_by_id': used_by_id,
                                'region': region
                            })
                            break
        except Exception as e:
            print(f"Error al obtener los grupos de seguridad en la región {region}: {e}")
            continue

    # Escribir datos a un archivo CSV en un directorio temporal
    temp_dir = tempfile.gettempdir()
    csv_file_name = f"{account_id}-SG-PorRevisar.csv"
    csv_file = f"{temp_dir}/{csv_file_name}"
    with open(csv_file, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=['group_id', 'group_name', 'ip_range', 'protocol', 'from_port', 'to_port', 'used_by', 'used_by_id', 'region'])
        writer.writeheader()
        for group in all_groups:
            writer.writerow(group)

    # Cargar el archivo CSV en el bucket
    s3.upload_file(csv_file, bucket_name, csv_file_name)

    return {
        'statusCode': 200,
        'body': 'Archivo CSV cargado exitosamente en el bucket público'
    }