// Use AWS SDK v3 in Node.js 22.x runtime
const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');
const client = new DynamoDBClient({});

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
        username,
        level: node.level,
        groups: node.groups || [],
        projects: node.projects || [],
        // manager field contains the username of the parent node
        manager: node.manager || null,
        permissions: node.permissions,
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
