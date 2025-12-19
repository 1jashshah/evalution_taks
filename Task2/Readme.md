Create a DynamoDB table books

![](images/1c08fd122e195e17a05283b31e9f2fcb1f08d4c8.png){width="6.260416666666667in"
height="1.75in"}

![](images/4fff5e4d657a0d9018f983b8ccfc0581968d3df4.png){width="6.260416666666667in"
height="3.125in"}

Create a lambda-role for execution and access dynamo db

![](images/4ab8ad3aa4094b23e54b5998bc6ca7a5a0776bbd.png){width="6.260416666666667in"
height="3.125in"}![](images/287687beaac5db6920a26635fa84c21b93af48e1.png){width="6.260416666666667in"
height="3.125in"}

Create Lambda functions:

a\. Add item

b\. Get item

c\. List items

![](images/2d22189977830d63dfac9c431661b0b9f8e5bdc6.png){width="6.260416666666667in"
height="3.125in"}

Create an API gateway

Create an HTTP API

![](images/06423960a31c7787e52c43f4305cb3076a7e8f2e.png){width="6.260416666666667in"
height="3.125in"}

Create Stage

![](images/14fb9e44abd79798470731157cdc91ab32d9518f.png){width="6.260416666666667in"
height="3.125in"}

Create Routes

POST /book

Get/books

Get/books/{id}

![](images/69a2539d9132ecca8a8e2ded737409a4b22cd482.png){width="6.260416666666667in"
height="2.4270833333333335in"}

Adding book to our dynamo db using below command

curl -X POST
<https://tchqo0u2jg.execute-api.ap-southeast-1.amazonaws.com/dev/book>
\\

-H \"Content-Type: application/json\" \\

-d \'{\"title\": \"My First Book\", \"author\": \"Jash Shah\"}\'

![](images/1aa64a0f6ce4adfa0de79f904f1d15c732bcc6ae.png){width="6.260416666666667in"
height="2.4791666666666665in"}

![](images/b61993c5bb06afaba641bdb660a3006a11bdea33.png){width="6.260416666666667in"
height="0.6666666666666666in"}

![](images/0df8b65e34d0ee99edbb4c4ee3f5fb52b8d0602f.png){width="6.260416666666667in"
height="3.5416666666666665in"}![](images/d463fc43822427df13501c34198b97d111b74d85.png){width="6.260416666666667in"
height="2.875in"}

![](images/1af2c10b3a14f900682ec42a1524160200ffa3f0.png){width="6.260416666666667in"
height="2.875in"}

Lambda functions

# **Addbook**
```bash
import json

import boto3

import uuid

dynamodb = boto3.resource(\'dynamodb\')

table = dynamodb.Table(\'books\')

def lambda_handler(event, context):

body = json.loads(event\[\'body\'\])

if \'title\' not in body or \'author\' not in body:

return {

\'statusCode\': 400,

\'body\': json.dumps({\'message\': \'title and author are required\'})

}

item = {

\'id\': str(uuid.uuid4()),

\'title\': body\[\'title\'\],

\'author\': body\[\'author\'\]

}

table.put_item(Item=item)

return {

\'statusCode\': 200,

\'body\': json.dumps(item)

}
```
# **Getbook**
```bash
import json

import boto3

dynamodb = boto3.resource(\'dynamodb\')

table = dynamodb.Table(\'books\')

def lambda_handler(event, context):

book_id = event\[\'pathParameters\'\]\[\'id\'\]

response = table.get_item(Key={\'id\': book_id})

if \'Item\' not in response:

return {

\'statusCode\': 404,

\'body\': json.dumps({\'message\': \'Book not found\'})

}

return {

\'statusCode\': 200,

\'body\': json.dumps(response\[\'Item\'\])

}
```
# **Listbooks**
```bash
import json

import boto3

dynamodb = boto3.resource(\'dynamodb\')

table = dynamodb.Table(\'books\')

def lambda_handler(event, context):

response = table.scan()

items = response.get(\'Items\', \[\])

return {

\'statusCode\': 200,

\'body\': json.dumps(items)

}
```
![](images/f7658fdb117d2a92387a18462fc4b8f0494be97a.png){width="6.260416666666667in"
height="2.875in"}
