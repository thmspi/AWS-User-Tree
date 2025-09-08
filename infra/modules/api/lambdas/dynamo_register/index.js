// Lambda to register user info into DynamoDB
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

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
    level = 1
  } = body;
  if (!username) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing username' }) };
  }
  const tableName = process.env.TABLE_NAME;
  try {
    // Store user record
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
        level,
        // initialize own children list
        children: []
      }
    }));
    // If manager defined, append this username to parent's children list
    if (manager) {
      await client.send(new UpdateCommand({
        TableName: tableName,
        Key: { username: manager },
        UpdateExpression: 'SET children = list_append(if_not_exists(children, :empty_list), :new_child)',
        ExpressionAttributeValues: {
          ':new_child': [username],
          ':empty_list': []
        }
      }));
    }
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
