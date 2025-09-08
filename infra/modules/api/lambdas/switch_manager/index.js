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
    // swap their manager fields
    const parentA = nodeA.manager;
    const parentB = nodeB.manager;
    await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerA}, UpdateExpression:'SET manager=:p', ExpressionAttributeValues:{':p':parentB}}));
    await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerB}, UpdateExpression:'SET manager=:p', ExpressionAttributeValues:{':p':parentA}}));
    // handle direct ancestor/descendant case
    if (parentB === managerA) {
      // managerA was direct parent of managerB
      // children of A without B
      const childrenA = (nodeA.children || []).filter(c => c !== managerB);
      // children of B plus A
      const childrenB = (nodeB.children || []).concat(managerA);
      // update children arrays
      await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerA}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':childrenA}}));
      await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerB}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':childrenB}}));
      // update parentA children list: replace A with B
      if (parentA) {
        const parentAItem = items.find(i=>i.username===parentA);
        const updated = (parentAItem.children || []).filter(c=>c!==managerA).concat(managerB);
        await doc.send(new UpdateCommand({ TableName: table, Key:{username:parentA}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':updated}}));
      }
      return { statusCode: 200, headers:{'Content-Type':'application/json','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'*','Access-Control-Allow-Methods':'POST,OPTIONS'}, body: JSON.stringify({ message:'Swapped'})};
    }
    // symmetric case: managerB was direct parent of managerA
    if (parentA === managerB) {
      // children of B without A
      const childrenB = (nodeB.children || []).filter(c => c !== managerA);
      // children of A plus B
      const childrenA = (nodeA.children || []).concat(managerB);
      // update children arrays
      await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerB}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':childrenB}}));
      await doc.send(new UpdateCommand({ TableName: table, Key:{username:managerA}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':childrenA}}));
      // update parentB children list: replace B with A under parentB's parent
      if (parentB) {
        const parentBItem = items.find(i=>i.username===parentB);
        const updated = (parentBItem.children || []).filter(c=>c!==managerB).concat(managerA);
        await doc.send(new UpdateCommand({ TableName: table, Key:{username:parentB}, UpdateExpression:'SET children=:c', ExpressionAttributeValues:{':c':updated}}));
      }
      return { statusCode: 200, headers:{'Content-Type':'application/json','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'*','Access-Control-Allow-Methods':'POST,OPTIONS'}, body: JSON.stringify({ message:'Swapped'})};
    }
    // swap children lists between managers
    // general case: handle inverted parent-child first
    const childrenA_orig = nodeA.children || [];
    const childrenB_orig = nodeB.children || [];
    if (childrenA_orig.includes(managerB) || childrenB_orig.includes(managerA)) {
      // invert direct relationship: remove and replace
      const newChildrenA = childrenA_orig.includes(managerB)
        ? childrenA_orig.filter(c => c !== managerB).concat(managerA)
        : childrenA_orig;
      const newChildrenB = childrenB_orig.includes(managerA)
        ? childrenB_orig.filter(c => c !== managerA).concat(managerB)
        : childrenB_orig;
      await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newChildrenA } }));
      await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': newChildrenB } }));
    } else {
      // standard swap children lists
      await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerA }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': childrenB_orig } }));
      await doc.send(new UpdateCommand({ TableName: table, Key: { username: managerB }, UpdateExpression: 'SET children = :c', ExpressionAttributeValues: { ':c': childrenA_orig } }));
    }
    // update parents' children lists
    if (parentA && parentB && parentA === parentB) {
      // both managers under same parent: swap positions in children array
      const parent = parentA;
      const parentItem = items.find(i => i.username === parent);
      const children = parentItem.children || [];
      const newChildren = children.map(c => {
        if (c === managerA) return managerB;
        if (c === managerB) return managerA;
        return c;
      });
      await doc.send(new UpdateCommand({
        TableName: table,
        Key: { username: parent },
        UpdateExpression: 'SET children = :c',
        ExpressionAttributeValues: { ':c': newChildren }
      }));
    } else {
      // distinct parents: remove and add accordingly
      async function updateChildList(parent, removeId, addId) {
        const parentItem = items.find(i => i.username === parent);
        const children = parentItem.children || [];
        const filtered = children.filter(c => c !== removeId);
        filtered.push(addId);
        await doc.send(new UpdateCommand({
          TableName: table,
          Key: { username: parent },
          UpdateExpression: 'SET children = :c',
          ExpressionAttributeValues: { ':c': filtered }
        }));
      }
      if (parentA) await updateChildList(parentA, managerA, managerB);
      if (parentB) await updateChildList(parentB, managerB, managerA);
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
