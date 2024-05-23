import boto3
import json
import os

dynamo = boto3.client('dynamodb')

def respond(statusCode, body):
    return {
        'statusCode': str(statusCode),
        'body': json.dumps(body),
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def lambda_handler(event, context):   
    id_ = event['pathParameters']['id']
    region = event['pathParameters']['region']

    item = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )['Item']

    occupied_qty = item['occupied_qty']['N']
    capacity = item['capacity']['N']

    if(int(occupied_qty) == int(capacity)):
        return respond(400, {
            'message': 'No free spaces'
        })
    
    dynamo.update_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        },
        UpdateExpression='SET occupied_qty = :val',
        ExpressionAttributeValues={
            ':val': {'N': str(int(occupied_qty) + 1)}
        }    
    )

    return respond(200, {
        'occupied_qty': int(occupied_qty) + 1
    })