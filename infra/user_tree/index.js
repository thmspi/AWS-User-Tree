const AWS = require('aws-sdk');
const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const tableName = process.env.TABLE_NAME;

  // Fetch all items
  let items = [];
  let params = { TableName: tableName };
  do {
    const data = await docClient.scan(params).promise();
    items = items.concat(data.Items);
    params.ExclusiveStartKey = data.LastEvaluatedKey;
  } while (params.ExclusiveStartKey);

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
      permissions: node.permissions,
      children: node.children.map(buildNode)
    };
  }

  const hierarchy = buildNode(root);

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(hierarchy)
  };
};
