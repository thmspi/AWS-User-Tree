// Lambda to delete a user from Cognito and DynamoDB, reassign children to parent
const {
  CognitoIdentityProviderClient,
  AdminDeleteUserCommand
} = require('@aws-sdk/client-cognito-identity-provider');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  DynamoDBDocumentClient,
  DeleteCommand,
  UpdateCommand,
  ScanCommand
} = require('@aws-sdk/lib-dynamodb');

const cognito = new CognitoIdentityProviderClient({});
const ddb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddb);

exports.handler = async (event) => {
  const poolId = process.env.USER_POOL_ID;
  const table = process.env.TABLE_NAME;
  try {
    const parts = event.rawPath.split('/');
    const username = decodeURIComponent(parts[parts.length - 1]);
    if (!username) return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
      },
      body: JSON.stringify({ message: 'Missing username' })
    };
    // fetch user's manager and children
    const scan = await docClient.send(new ScanCommand({ TableName: table }));
    const items = scan.Items;
    const user = items.find(i => i.username === username);
    if (!user) return {
      statusCode: 404,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
      },
      body: JSON.stringify({ message: 'User not found' })
    };
    // block deleting root user (no parent)
    if (!user.manager) {
      return {
        statusCode: 403,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
        },
        body: JSON.stringify({ message: 'Cannot delete root user' })
      };
    }
    const parent = user.manager;
    const children = user.children || [];
    // delete from Cognito
    await cognito.send(new AdminDeleteUserCommand({ UserPoolId: poolId, Username: username }));
    // reassign children to parent
    for (const child of children) {
      await docClient.send(new UpdateCommand({
        TableName: table,
        Key: { username: child },
        UpdateExpression: 'SET manager = :parent',
        ExpressionAttributeValues: { ':parent': parent }
      }));
      // append to parent children list
      await docClient.send(new UpdateCommand({
        TableName: table,
        Key: { username: parent },
        UpdateExpression: 'SET children = list_append(if_not_exists(children, :empty), :new)',
        ExpressionAttributeValues: { ':new': [child], ':empty': [] }
      }));
    }
    // delete user from DynamoDB
    await docClient.send(new DeleteCommand({ TableName: table, Key: { username } }));
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
      },
      body: JSON.stringify({ message: 'User deleted' })
    };
  } catch (err) {
    console.error('Error deleting user:', err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
      },
      body: JSON.stringify({ message: err.message })
    };
  }
};
