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
    region = event['pathParameters']['region']
    userEmail = event.get("requestContext").get("authorizer").get("claims").get("email")

    parking = dynamo.query(
        TableName=os.environ['table_name'],
        KeyConditionExpression='#r = :r',
        ExpressionAttributeNames={'#r': 'region'},
        ExpressionAttributeValues={':r': {'S': region}}
    )

    user = dynamo.get_item(
        TableName=os.environ['user_table'],
        Key={
            'username': {'S': userEmail}
        }
    ).get('Item', {})

    parking_spots = []

    for item in parking['Items']:
        parking_spots.append({
            **item,
            'occupiedByUser': user.get('occupied_parking', {}).get('S', '') == region+item['id']['S']
        })

    return respond(None, parking_spots)
