// Lambda to create and delete teams in DynamoDB
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
  const tableName = process.env.TEAMS_TABLE;
  try {
    const method = event.requestContext.http.method;
    if (method === 'POST') {
      const body = JSON.parse(event.body || '{}');
      const { name, color } = body;
      if (!name || !color) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing name or color' }) };
      }
      await client.send(new PutCommand({
        TableName: tableName,
        Item: { team_id: name, color }
      }));
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ message: 'Team created' })
      };
    } else if (method === 'DELETE') {
      // path param at /teams/{team}
      const parts = event.rawPath.split('/');
      const name = decodeURIComponent(parts[parts.length - 1]);
      if (!name) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing team name' }) };
      }
      await client.send(new DeleteCommand({
        TableName: tableName,
        Key: { team_id: name }
      }));
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ message: 'Team deleted' })
      };
    }
    return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
  } catch (err) {
    console.error('Error in manage_team:', err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ message: err.message })
    };
  }
};
