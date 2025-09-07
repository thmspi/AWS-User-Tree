// Lambda to fetch all manager usernames from DynamoDB user_tree table
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
  const tableName = process.env.USER_TABLE;
  try {
    let items = [];
    let params = { TableName: tableName };
    do {
      const data = await client.send(new ScanCommand(params));
      items = items.concat(data.Items || []);
      params.ExclusiveStartKey = data.LastEvaluatedKey;
    } while (params.ExclusiveStartKey);

    // build map username->item
    const treeMap = {};
    items.forEach(i => {
      treeMap[i.username] = { ...i, children: i.children || [] };
    });
    // determine current user (from query param)
    const currentUser = event.queryStringParameters?.user;
    const headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Methods': 'GET,OPTIONS'
    };
    // only managers can fetch subordinate managers
    const rootNode = treeMap[currentUser];
    if (!rootNode || !rootNode.is_manager) {
      return { statusCode: 403, headers, body: JSON.stringify({ message: 'Unauthorized' }) };
    }
    // collect managers under currentUser
    let managers = [];
    function traverse(user) {
      const node = treeMap[user];
      if (!node || !node.children) return;
      node.children.forEach(child => {
        const childNode = treeMap[child];
        if (childNode?.is_manager) managers.push(child);
        traverse(child);
      });
    }
    // include self and descendant managers
    managers.push(currentUser);
    traverse(currentUser);

    return {
      statusCode: 200,
      headers,
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
