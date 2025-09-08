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
  // locate nodes and prepare temp variables
  const nodeA = items.find(i => i.username === managerA) || {};
  const nodeB = items.find(i => i.username === managerB) || {};
  const parentA = nodeA.manager;
    const parentB = nodeB.manager;
    const childrenA = nodeA.children || [];
    const childrenB = nodeB.children || [];
    // compute new parent children lists
    let newPaChildren = parentA ? (items.find(i => i.username === parentA).children || []) : [];
    let newPbChildren = parentB ? (items.find(i => i.username === parentB).children || []) : [];
    if (parentA) {
      newPaChildren = newPaChildren.filter(c => c !== managerA).concat(managerB);
    }
    if (parentB) {
      newPbChildren = newPbChildren.filter(c => c !== managerB).concat(managerA);
    }
    // compute new children lists for managers
    let newAChildren = [];
    let newBChildren = [];
    if (parentB === managerA) {
      // case: A was parent of B
      newAChildren = childrenB.concat(managerA);
      newBChildren = childrenA.filter(c => c !== managerB);
    } else if (parentA === managerB) {
      // case: B was parent of A
      newBChildren = childrenA.concat(managerB);
      newAChildren = childrenB.filter(c => c !== managerA);
    } else {
      // normal swap
      newAChildren = childrenB;
      newBChildren = childrenA;
    }
    // Apply updates: swap managers, update parent children, update manager children
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET manager = :p', ExpressionAttributeValues: { ':p': parentB } }));
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET manager = :p', ExpressionAttributeValues: { ':p': parentA } }));
    if (parentA) await doc.send(new UpdateCommand({ TableName: table, Key: { username: parentA }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newPaChildren } }));
    if (parentB) await doc.send(new UpdateCommand({ TableName: table, Key: { username: parentB }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newPbChildren } }));
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newAChildren } }));
  await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newBChildren } }));
    // final response
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
