// Lambda to fetch all manager usernames from DynamoDB user_tree table
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async () => {
  const tableName = process.env.USER_TABLE;
  try {
    let items = [];
    let params = { TableName: tableName };
    do {
      const data = await client.send(new ScanCommand(params));
      items = items.concat(data.Items || []);
      params.ExclusiveStartKey = data.LastEvaluatedKey;
    } while (params.ExclusiveStartKey);

    // filter managers
    const managers = items
      .filter(item => item.is_manager)
      .map(item => item.username);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify(managers)
    };
  } catch (err) {
    console.error('Error fetching managers:', err);
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
