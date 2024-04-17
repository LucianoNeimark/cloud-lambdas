import boto3
import json
import os

dynamo = boto3.client('dynamodb')

def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else json.dumps(res),
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def lambda_handler(event, context): 
    id_ = event['pathParameters']['id']
    region = event['queryStringParameters']['region']

    parking = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'N': id_}
        }
    )

    return respond(None, parking['Item'])