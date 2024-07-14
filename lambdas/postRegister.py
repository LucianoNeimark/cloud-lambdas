import boto3
import json
import os
import uuid

dynamo = boto3.client('dynamodb')


def lambda_handler(event, context):
    email = event.get('request').get('userAttributes').get('email')

    dynamo.put_item(
        TableName=os.environ['user_table'],
        Item={
            'username': {'S': email}
        }
    )
    return event    

    