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
    lot = region+id_

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

    user = dynamo.get_item(
        TableName=os.environ['user_table'],
        Key={
            'username': {'S': userEmail}
        }
    ).get('Item', {})

    if user.get('occupied_parking', {}).get('S', '') != lot:
        return respond(409, {
            'message': 'Cannot free a space you are not occupying'
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

    dynamo.update_item(
        TableName=os.environ['user_table'],
        Key={
            'username': {'S': userEmail}
        },
        UpdateExpression='SET occupied_parking = :val',
        ExpressionAttributeValues={
            ':val': {'S': ""}
        }    
    )

    return respond(200, {
        'occupied_qty': int(current_occupied) - 1
    })