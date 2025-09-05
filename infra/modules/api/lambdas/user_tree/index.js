// Use AWS SDK v3 DynamoDB DocumentClient for automatic marshalling
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');
// DocumentClient wraps DynamoDBClient and unmarshals attribute values
const ddbClient = new DynamoDBClient({});
const client = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
  console.log('Lambda handler invoked with event:', JSON.stringify(event));
  const tableName = process.env.TABLE_NAME;
  try {
    console.log('Using DynamoDB table:', tableName);

    // Fetch all items
    let items = [];
    let params = { TableName: tableName };
    do {
      console.log('Scanning DynamoDB with params:', JSON.stringify(params));
      const data = await client.send(new ScanCommand(params));
      console.log('Fetched batch items count:', data.Items.length);
      // DocumentClient returns plain JS objects
      items = items.concat(data.Items);
      params.ExclusiveStartKey = data.LastEvaluatedKey;
    } while (params.ExclusiveStartKey);
    console.log('Total items fetched:', items.length);

    // Build hierarchy map
    const tree = {};
    items.forEach(item => {
      tree[item.username] = { ...item, children: [] };
    });

    // Assign children to parents
    Object.values(tree).forEach(node => {
      if (node.manager && tree[node.manager]) {
        tree[node.manager].children.push(node.username);
      }
    });

    // Identify root (admin)
    const root = items.find(i => i.level === 0)?.username;

    // Recursive build
    function buildNode(username) {
      const node = tree[username];
      if (!node) return null;
      return {
        given_name: node.given_name || null,
        family_name: node.family_name || null,
        username: node.username,
        level: node.level,
  team: node.team || [],
  job: node.job || [],
        manager: node.manager || null,
        permissions: node.permissions,
        // include manager status flag for UI coloring
        is_manager: node.is_manager || false,
        children: node.children.map(buildNode)
      };
    }

    const hierarchy = buildNode(root);
    const response = {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify(hierarchy)
    };
    console.log('Returning response :', response);
    return response;
  } catch (err) {
    console.error('Error in Lambda handler:', err);
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
