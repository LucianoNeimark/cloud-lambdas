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
    # return all the parking lots
    response = dynamo.scan(
        TableName=os.environ['table_name']
    )

    return respond(None, response['Items'])