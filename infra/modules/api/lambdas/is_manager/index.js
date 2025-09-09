// Lambda to determine whether a given user is a manager
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
  const tableName = process.env.USER_TABLE || process.env.TABLE_NAME;
  try {
    // support query param ?user=USERNAME or path parameter /users/{username}
    const username = event.queryStringParameters?.user || event.pathParameters?.username;
    if (!username) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        body: JSON.stringify({ message: 'username required (query param "user" or path param)' })
      };
    }

    const params = { TableName: tableName, Key: { username } };
    const data = await client.send(new GetCommand(params));
    const item = data.Item;

    const isManager = !!(item && item.is_manager);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify({ is_manager: isManager })
    };
  } catch (err) {
    console.error('is_manager error:', err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify({ message: err.message })
    };
  }
};
