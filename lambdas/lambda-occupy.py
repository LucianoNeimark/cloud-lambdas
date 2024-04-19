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
    region = event['pathParameters']['region']

    current_free_spaces = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )['Item']['cantidad_ocupada']['N']

    dynamo.update_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        },
        UpdateExpression='SET cantidad_ocupada = :val',
        ExpressionAttributeValues={
            ':val': {'N': str(int(current_free_spaces) + 1)}
        }    
    )

    return respond(None, {
        'cantidad_ocupada': int(current_free_spaces) - 1
    })