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

    item = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )

    if 'Item' not in item:
        return respond(404, {
            'message': 'Item not found'
        })

    current_occupied = item['Item']['occupied_qty']['N']

    if(int(current_occupied) == 0):
        return respond(400, {
            'message': 'No cars in parking'
        })


    dynamo.update_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        },
        UpdateExpression='SET occupied_qty = :val',
        ExpressionAttributeValues={
            ':val': {'N': str(int(current_occupied) - 1)}
        }    
    )

    return respond(None, {
        'occupied_qty': int(current_occupied) - 1
    })