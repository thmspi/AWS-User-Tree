// Lambda to register a user in Cognito and attach permissions via Cognito groups
const { 
  CognitoIdentityProviderClient, 
  AdminCreateUserCommand, 
  AdminAddUserToGroupCommand 
} = require('@aws-sdk/client-cognito-identity-provider');

const client = new CognitoIdentityProviderClient({});

exports.handler = async (event) => {
  const poolId = process.env.USER_POOL_ID;
  let body;
  try {
    body = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON' }) };
  }
  const { username, given_name, family_name, password } = body;
  if (!username || !password) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing username or password' }) };
  }

  try {
    // Create Cognito user with temporary password
    await client.send(new AdminCreateUserCommand({
      UserPoolId: poolId,
      Username: username,
      TemporaryPassword: password,
      UserAttributes: [
        { Name: 'given_name', Value: given_name },
        { Name: 'family_name', Value: family_name }
      ],
      MessageAction: 'SUPPRESS'
    }));
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({ message: 'User registered in Cognito' })
    };
  } catch (err) {
    console.error('Error in cognito_register:', err);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({ message: err.message })
    };
  }
};
