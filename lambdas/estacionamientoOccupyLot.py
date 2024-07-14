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
    userEmail = event.get("requestContext").get("authorizer").get("claims").get("email")

    item = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )['Item']

    user = dynamo.get_item(
        TableName=os.environ['user_table'],
        Key={
            'username': {'S': userEmail}
        }
    ).get('Item', {})


    if user.get('occupied_parking', {}).get('S', '') != '':
        return respond(409, {
            'message': 'Already occupied a parking spot'
        })

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


    dynamo.update_item(
        TableName=os.environ['user_table'],
        Key={
            'username': {'S': userEmail}
        },
        UpdateExpression='SET occupied_parking = :val',
        ExpressionAttributeValues={
            ':val': {'S': (region+id_)}
        }    
    )


    return respond(200, {
        'occupied_qty': int(occupied_qty) + 1
    })