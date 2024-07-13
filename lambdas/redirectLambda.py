import os

def lambda_handler(event, context):
    print(event)
    print(event.get('rawQueryString', ''))
    return {
        'statusCode': '302',
        'headers': {
            'Location': "http://" + os.environ['frontend_url'] + '?' + event.get('rawQueryString', ''),
        },
    }
