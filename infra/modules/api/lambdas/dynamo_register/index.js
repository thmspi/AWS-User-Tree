// Lambda to register user info into DynamoDB
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
  let body;
  try {
    body = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON' }) };
  }
  const {
    username,
    given_name,
    family_name,
    job,
    team,
    manager,
    is_manager,
    permissions = [],
    level = 1
  } = body;
  if (!username) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing username' }) };
  }
  const tableName = process.env.TABLE_NAME;
  try {
    await client.send(new PutCommand({
      TableName: tableName,
      Item: {
        username,
        given_name,
        family_name,
        job,
        team,
        manager,
        is_manager,
        permissions,
        level
      }
    }));
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({ message: 'User stored in DynamoDB' })
    };
  } catch (err) {
    console.error('Error in dynamo_register:', err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({ message: err.message })
    };
  }
};
