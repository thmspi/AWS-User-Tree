// Lambda to fetch all teams with names and colors from DynamoDB teams table
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async () => {
  const tableName = process.env.TEAMS_TABLE;
  try {
    let items = [];
    let params = { TableName: tableName };
    do {
      const data = await client.send(new ScanCommand(params));
      items = items.concat(data.Items || []);
      params.ExclusiveStartKey = data.LastEvaluatedKey;
    } while (params.ExclusiveStartKey);

    const teams = items.map(item => ({ name: item.team_id, color: item.color || '#0073bb' }));
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify(teams)
    };
  } catch (err) {
    console.error('Error fetching teams:', err);
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
