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
    if (!managerA || !managerB) return { statusCode:400, body: 'Missing managers' };
    // scan entire table
    const scan = await doc.send(new ScanCommand({ TableName: table }));
    const items = scan.Items;
    // find nodes
    const nodeA = items.find(i=>i.username === managerA);
    const nodeB = items.find(i=>i.username === managerB);
    if (!nodeA || !nodeB) return { statusCode:404, body: 'Manager not found' };
    // swap their manager fields
    const parentA = nodeA.manager;
    const parentB = nodeB.manager;
    await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerA}, UpdateExpression:'SET manager=:p', ExpressionAttributeValues:{':p':parentB}}));
    await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerB}, UpdateExpression:'SET manager=:p', ExpressionAttributeValues:{':p':parentA}}));
    // update parents' children lists
    // remove A from parentA and add B, vice versa
    async function swapChild(parent, oldChild, newChild){
      const parentItem = items.find(i=>i.username===parent);
      const children = parentItem.children || [];
      const updated = children.filter(c=>c!==oldChild).concat(newChild);
      await doc.send(new UpdateCommand({TableName:table,Key:{username:parent},UpdateExpression:'SET children=:c',ExpressionAttributeValues:{':c':updated}}));
    }
    if (parentA) await swapChild(parentA, managerA, managerB);
    if (parentB) await swapChild(parentB, managerB, managerA);
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
