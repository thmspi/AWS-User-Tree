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
    console.log('Scan result count:', items.length);
    // locate selected nodes
    const nodeA = items.find(i => i.username === managerA) || {};
    const nodeB = items.find(i => i.username === managerB) || {};
    const parentA = nodeA.manager || null;
    const parentB = nodeB.manager || null;
    const childrenA = [...(nodeA.children || [])];
    const childrenB = [...(nodeB.children || [])];
    console.log('Initial state:', { managerA, managerB, parentA, parentB, childrenA, childrenB });
    // snapshot parent children
    let paChildren = parentA ? [...(items.find(i => i.username === parentA).children || [])] : [];
    let pbChildren = parentB ? [...(items.find(i => i.username === parentB).children || [])] : [];
    console.log('Parent lists before swap:', { paChildren, pbChildren });
    // detect direct parent-child relations
    const aIsParentOfB = parentB === managerA;
    const bIsParentOfA = parentA === managerB;
    // prepare new values
    let newMgrA, newMgrB, newAChildren, newBChildren;
    if (aIsParentOfB) {
      console.log('Case: A is parent of B');
      // A was parent of B
      if (parentA) paChildren = paChildren.filter(c => c !== managerA).concat(managerB);
      newAChildren = childrenB;
      newBChildren = childrenA.filter(c => c !== managerB);
      newMgrA = managerB;
      newMgrB = parentA;
    } else if (bIsParentOfA) {
      console.log('Case: B is parent of A');
      // B was parent of A
      if (parentB) pbChildren = pbChildren.filter(c => c !== managerB).concat(managerA);
      newBChildren = childrenA;
      newAChildren = childrenB.filter(c => c !== managerA);
      newMgrA = parentB;
      newMgrB = managerA;
    } else {
      console.log('Case: Normal swap');
      // normal swap
      if (parentA) paChildren = paChildren.filter(c => c !== managerA).concat(managerB);
      if (parentB) pbChildren = pbChildren.filter(c => c !== managerB).concat(managerA);
      newAChildren = childrenB;
      newBChildren = childrenA;
      newMgrA = parentB;
      newMgrB = parentA;
    }
    console.log('Computed swap values:', { newMgrA, newMgrB, paChildren, pbChildren, newAChildren, newBChildren });
    // apply parent children updates
    if (parentA) {
      console.log('Updating children for parentA:', parentA, paChildren);
      await doc.send(new UpdateCommand({
        TableName: table, Key: { username: parentA },
        UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': paChildren }
      }));
    }
    if (parentB) {
      console.log('Updating children for parentB:', parentB, pbChildren);
      await doc.send(new UpdateCommand({
        TableName: table, Key: { username: parentB },
        UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': pbChildren }
      }));
    }
    // apply manager swaps
    console.log('Updating manager for A:', managerA, '->', newMgrA);
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET manager = :m', ExpressionAttributeValues: { ':m': newMgrA } }));
    console.log('Updating manager for B:', managerB, '->', newMgrB);
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET manager = :m', ExpressionAttributeValues: { ':m': newMgrB } }));
    // apply new children lists for swapped nodes
    console.log('Updating children for A:', managerA, newAChildren);
    await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newAChildren } }));
    console.log('Updating children for B:', managerB, newBChildren);
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
