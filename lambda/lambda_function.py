import json
import boto3
import os

def lambda_handler(event, context):
    """
    Fonction Lambda pour démarrer ou arrêter une instance EC2
    Compatible avec LocalStack via endpoint dynamique - SANS FALLBACK LOCALHOST
    """
    
    # Récupérer l'endpoint AWS - OBLIGATOIRE, pas de fallback
    aws_endpoint = os.environ.get('AWS_ENDPOINT')
    
    if not aws_endpoint:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'AWS_ENDPOINT not configured in Lambda environment variables'
            })
        }
    
    # Initialisation du client EC2 avec endpoint dynamique
    ec2 = boto3.client(
        'ec2',
        endpoint_url=aws_endpoint,
        region_name='us-east-1',
        aws_access_key_id='test',
        aws_secret_access_key='test',
        verify=False  # Désactiver la vérification SSL pour LocalStack
    )
    
    try:
        # Récupération de l'action depuis l'événement
        body = json.loads(event.get('body', '{}'))
        action = body.get('action', '').lower()
        instance_id = body.get('instance_id', os.environ.get('INSTANCE_ID'))
        
        if not instance_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Instance ID is required'})
            }
        
        # Exécution de l'action
        if action == 'start':
            response = ec2.start_instances(InstanceIds=[instance_id])
            message = f"Instance {instance_id} is starting"
            
        elif action == 'stop':
            response = ec2.stop_instances(InstanceIds=[instance_id])
            message = f"Instance {instance_id} is stopping"
            
        elif action == 'status':
            response = ec2.describe_instances(InstanceIds=[instance_id])
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            message = f"Instance {instance_id} status: {state}"
            
        else:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Invalid action. Use: start, stop, or status'
                })
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': message,
                'instance_id': instance_id,
                'action': action,
                'endpoint': aws_endpoint
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'endpoint': aws_endpoint
            })
        }
