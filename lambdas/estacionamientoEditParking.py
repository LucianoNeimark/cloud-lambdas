import json
import boto3
import os

def lambda_handler(event, context):
    id_ = event.get("pathParameters").get("id")
    region = event.get("pathParameters").get("region")
    body = json.loads(event['body'])
    dynamo = boto3.client('dynamodb')

    userEmail = event.get("requestContext").get("authorizer").get("claims").get("email")

    parking = dynamo.get_item(
        TableName=os.environ['table_name'],
        Key={
            'region': {'S': region},
            'id': {'S': id_}
        }
    )
    
    if 'Item' in parking:
        item = parking['Item']

        if not 'owner' in item or item['owner'].get('S', '') != userEmail:
            return {
                'statusCode': 403
            }
        
        if 'name' in body:
            item['name'] = {'S': body['name']}
        
        if 'capacity' in body:
            if int(body['capacity']) < int(item['occupied_qty'].get('N', 0)):
                return {
                    'statusCode': 409,
                    'body': 'New capacity can not be less than occupied spaces'
                }

            item['capacity'] = {'N': str(body['capacity'])}

        dynamo.put_item(
            TableName=os.environ['table_name'],
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



