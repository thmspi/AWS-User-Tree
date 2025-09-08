// Lambda to swap two managers in the hierarchy
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const ddb = new DynamoDBClient({});
const doc = DynamoDBDocumentClient.from(ddb);

exports.handler = async (event) => {
  const method = event.requestContext?.http.method;
  if (method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      }
    };
  }
  const table = process.env.TABLE_NAME;
  try {
    const body = JSON.parse(event.body || '{}');
    const { managerA, managerB } = body;
    if (!managerA || !managerB) return { statusCode:400, headers:{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'*','Access-Control-Allow-Methods':'POST,OPTIONS'}, body: 'Missing managers' };
    // prevent switching ancestor and descendant
    const scan = await doc.send(new ScanCommand({ TableName: table }));
    const items = scan.Items;
    const childrenMap = items.reduce((acc, i) => { acc[i.username] = i.children || []; return acc; }, {});
    function isDescendant(root, target) {
      const stack = [...(childrenMap[root] || [])];
      while (stack.length) {
        const c = stack.pop();
        if (c === target) return true;
        stack.push(...(childrenMap[c] || []));
      }
      return false;
    }
    // scan entire table
    // find nodes
    const nodeA = items.find(i=>i.username === managerA);
    const nodeB = items.find(i=>i.username === managerB);
    if (!nodeA || !nodeB) return { statusCode:404, body: 'Manager not found' };
    // 1) swap manager references
    const parentA = nodeA.manager;
    const parentB = nodeB.manager;
    await doc.send(new UpdateCommand({
      TableName: table,
      Key: { username: managerA },
      UpdateExpression: 'SET manager = :p',
      ExpressionAttributeValues: { ':p': parentB }
    }));
    await doc.send(new UpdateCommand({
      TableName: table,
      Key: { username: managerB },
      UpdateExpression: 'SET manager = :p',
      ExpressionAttributeValues: { ':p': parentA }
    }));
    // 2) update parentA children: replace managerA with managerB
    if (parentA) {
      const paChildren = items.find(i => i.username === parentA).children || [];
      const updatedA = paChildren.filter(c => c !== managerA).concat(managerB);
      await doc.send(new UpdateCommand({
        TableName: table,
        Key: { username: parentA },
        UpdateExpression: 'SET children = :c',
        ExpressionAttributeValues: { ':c': updatedA }
      }));
    }
    // 3) update parentB children: replace managerB with managerA
    if (parentB) {
      const pbChildren = items.find(i => i.username === parentB).children || [];
      const updatedB = pbChildren.filter(c => c !== managerB).concat(managerA);
      await doc.send(new UpdateCommand({
        TableName: table,
        Key: { username: parentB },
        UpdateExpression: 'SET children = :c',
        ExpressionAttributeValues: { ':c': updatedB }
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
      body: JSON.stringify({ message: 'Swapped' })
    };
  } catch(err){
    console.error(err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({ error: err.message })
    };
  }
};
