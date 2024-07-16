import os
import boto3
import json

def respond(status_code, message):
    return {
        'statusCode': str(status_code),
        'body': json.dumps({'message': message}),
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def lambda_handler(event, context):
    userClaims = event.get("requestContext").get("authorizer").get("claims")
    if userClaims.get("cognito:groups", []).count("estacionamiento-admin") > 0:
        return respond(403, "You are already an owner.")
    
    params = {
        'GroupName': 'estacionamiento-admin',
        'UserPoolId': os.environ['user_pool_id'],
        'Username': userClaims.get('sub'),
    }
    cognito = boto3.client('cognito-idp')
    response = cognito.admin_add_user_to_group(**params)
    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        return respond(201, "You are now an owner.")
    else:
        return respond(500, "Failed to add you to the group.")