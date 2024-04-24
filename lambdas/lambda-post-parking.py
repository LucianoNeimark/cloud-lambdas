import boto3
import json
import os
import uuid

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
    try:
        region = event.get("pathParameters").get("region")

        if not region:
            return respond(400, "Region parameter is required.")

        body = json.loads(event.get("body") or '{}')

        parking = dynamo.put_item(
            TableName=os.environ['table_name'],
            Item={
                'region': {'S': region},
                'id': {'S': str(uuid.uuid4())},
                'name': {'S': body.get("name")},
                'capacity': {'N': str(body.get("capacity", 0))},  # Default to 0 if capacity is missing
                'occupied_qty': {'N': str(body.get("occupied_qty", 0))}  # Default to 0 if occupied_qty is missing
            }
        )

        if parking['ResponseMetadata']['HTTPStatusCode'] == 200:
            return respond(201, "Parking created successfully.")
        else:
            return respond(500, "Failed to create parking.")

    except Exception as e:
        return respond(500, str(e))
