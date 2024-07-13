import os
import boto3
import json

def lambda_handler(event, context):
    print(event)
    body = json.loads(event['body'])
    print(body)

    params = {
        'GroupName': 'estacionamiento-admin',
        'UserPoolId': os.environ['user_pool_id'],
        'Username': body.get('username'),
    }
    print(params)
    cognito = boto3.client('cognito-idp')
    response = cognito.admin_add_user_to_group(**params)
    print(response)
    return {
        'statusCode': '200'
    }