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
    userEmail = event.get("requestContext").get("authorizer").get("claims").get("email")

    try:
        id_ = event['pathParameters']['id']
        region = event['pathParameters']['region']
        lot = region+id_


        parking = dynamo.get_item(
            TableName=os.environ['table_name'],
            Key={
                'region': {'S': region},
                'id': {'S': id_}
            }
        )

        user = dynamo.get_item(
            TableName=os.environ['user_table'],
            Key={
                'username': {'S': userEmail}
            }
        ).get('Item', {})

        if 'Item' not in parking:
            return respond(404, 'Item not found')


        parkingData = {
            'Item': parking['Item'], 
            'occupiedByUser': user.get('occupied_parking', {}).get('S', '') == lot
        }        

        return respond(200, parkingData)
    except Exception as e:
        return respond(500, str(e))


