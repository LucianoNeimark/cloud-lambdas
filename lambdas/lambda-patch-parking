import json
import boto3
import os

def lambda_handler(event, context):
    id_ = event.get("pathParameters").get("id")
    region = event.get("pathParameters").get("region")
    body = json.loads(event['body'])
    dynamo = boto3.client('dynamodb')

    response = dynamo.get_item(
        TableName='estacionamiento',
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )
    
    if 'Item' in response:
        item = response['Item']
        
        if 'name' in body:
            item['name'] = {'S': body['name']}
        
        if 'capacity' in body:
            item['capacity'] = {'N': str(body['capacity'])}

        dynamo.put_item(
            TableName='estacionamiento',
            Item=item
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps(body['name'])
        }
    else:
        return {
            'statusCode': 404,
            'body': 'Item not found'
        }
