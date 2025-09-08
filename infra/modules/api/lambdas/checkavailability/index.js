// Lambda to check if a Cognito username is available
const { CognitoIdentityProviderClient, AdminGetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');

const cognitoClient = new CognitoIdentityProviderClient({});

exports.handler = async (event) => {
  let username;
  try {
    const body = JSON.parse(event.body);
    username = body.username;
  } catch {
    return { statusCode: 400, body: JSON.stringify({ message: 'Invalid request' }) };
  }

  const poolId = process.env.USER_POOL_ID;
  if (!username || !poolId) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing username or pool id' }) };
  }

  try {
    // Try to get the user; if found, it's not available
    await cognitoClient.send(new AdminGetUserCommand({
      UserPoolId: poolId,
      Username: username
    }));
    return {
      statusCode: 200,
      body: JSON.stringify({ available: false })
    };
  } catch (err) {
    if (err.name === 'UserNotFoundException') {
      // Username is free
      return {
        statusCode: 200,
        body: JSON.stringify({ available: true })
      };
    }
    console.error('Error checking availability:', err);
    return { statusCode: 500, body: JSON.stringify({ message: err.message }) };
  }
};
