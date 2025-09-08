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
    // fetch current items and snapshot relationships
    const scan = await doc.send(new ScanCommand({ TableName: table }));
    const items = scan.Items;
    // locate selected nodes
    const nodeA = items.find(i => i.username === managerA) || {};
    const nodeB = items.find(i => i.username === managerB) || {};
    const parentA = nodeA.manager || null;
    const parentB = nodeB.manager || null;
    const childrenA = [...(nodeA.children || [])];
    const childrenB = [...(nodeB.children || [])];
    // snapshot parent children
    let paChildren = parentA ? [...(items.find(i => i.username === parentA).children || [])] : [];
    let pbChildren = parentB ? [...(items.find(i => i.username === parentB).children || [])] : [];
    // detect direct parent-child relations
    const aIsParentOfB = parentB === managerA;
    const bIsParentOfA = parentA === managerB;
    // prepare new values
    let newMgrA, newMgrB, newAChildren, newBChildren;
    if (aIsParentOfB) {
      // A was parent of B
      if (parentA) paChildren = paChildren.filter(c => c !== managerA).concat(managerB);
      newAChildren = childrenB;
      newBChildren = childrenA.filter(c => c !== managerB);
      newMgrA = managerB;
      newMgrB = parentA;
    } else if (bIsParentOfA) {
      // B was parent of A
      if (parentB) pbChildren = pbChildren.filter(c => c !== managerB).concat(managerA);
      newBChildren = childrenA;
      newAChildren = childrenB.filter(c => c !== managerA);
      newMgrA = parentB;
      newMgrB = managerA;
    } else {
      // normal swap
      if (parentA) paChildren = paChildren.filter(c => c !== managerA).concat(managerB);
      if (parentB) pbChildren = pbChildren.filter(c => c !== managerB).concat(managerA);
      newAChildren = childrenB;
      newBChildren = childrenA;
      newMgrA = parentB;
      newMgrB = parentA;
    }
    // apply parent children updates
    if (parentA) await doc.send(new UpdateCommand({
      TableName: table, Key: { username: parentA },
      UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': paChildren }
    }));
    if (parentB) await doc.send(new UpdateCommand({
      TableName: table, Key: { username: parentB },
      UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': pbChildren }
    }));
    // apply manager swaps
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET manager = :m', ExpressionAttributeValues: { ':m': newMgrA } }));
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET manager = :m', ExpressionAttributeValues: { ':m': newMgrB } }));
    // apply new children lists for swapped nodes
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
