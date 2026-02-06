import json
import boto3
import os

def lambda_handler(event, context):
    """
    Fonction Lambda pour contrôler une instance EC2
    Supporte GET avec query params ou POST avec body JSON
    """
    
    # Récupérer l'endpoint AWS
    aws_endpoint = os.environ.get('AWS_ENDPOINT')
    
    if not aws_endpoint:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'AWS_ENDPOINT not configured'})
        }
    
    # Initialiser le client EC2
    ec2 = boto3.client(
        'ec2',
        endpoint_url=aws_endpoint,
        region_name='us-east-1',
        aws_access_key_id='test',
        aws_secret_access_key='test',
        verify=False
    )
    
    try:
        # Déterminer l'action depuis le path
        path = event.get('path', '')
        action = path.split('/')[-1].lower()  # Récupère 'start', 'stop' ou 'status'
        
        # Instance ID depuis l'environnement
        instance_id = os.environ.get('INSTANCE_ID')
        
        if not instance_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Instance ID not configured'})
            }
        
        # Exécuter l'action
        if action == 'start':
            ec2.start_instances(InstanceIds=[instance_id])
            message = f"Instance {instance_id} is starting"
            
        elif action == 'stop':
            ec2.stop_instances(InstanceIds=[instance_id])
            message = f"Instance {instance_id} is stopping"
            
        elif action == 'status':
            response = ec2.describe_instances(InstanceIds=[instance_id])
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            message = f"Instance {instance_id} status: {state}"
            
        else:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': f'Invalid action: {action}'})
            }
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'message': message,
                'instance_id': instance_id,
                'action': action
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }
