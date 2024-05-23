import boto3
import json
import os

dynamo = boto3.client('dynamodb')

def respond(status_code, message):
    return {
        'statusCode': str(status_code),
        'body': json.dumps({'message': message}),
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def lambda_handler(event, context):

    try:
        id_ = event['pathParameters']['id']
        region = event['pathParameters']['region']


        parking = dynamo.get_item(
            TableName=os.environ['table_name'],
            Key={
                'region': {'S': region},
                'id': {'S': id_}
            }
        )

        if 'Item' not in parking:
            return respond(404, 'Item not found')

        return respond(200, parking)
    except Exception as e:
        return respond(500, str(e))