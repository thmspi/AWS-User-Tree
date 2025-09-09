// Lambda: verify_mail
// Purpose: mark user's email as verified in Cognito using AdminUpdateUserAttributes
// Expected environment variables:
//   USER_POOL_ID - the Cognito User Pool ID
// Invocation:
//  - POST JSON body { "username": "..." }
//  - or, if behind a Cognito authorizer, username will be taken from event.requestContext.authorizer.claims['cognito:username']

const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

const USER_POOL_ID = process.env.USER_POOL_ID;
const CORS_HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Allow-Methods': 'POST,OPTIONS'
};

exports.handler = async function(event) {
  try {
    console.log('verify_mail invoked', { envUserPool: !!USER_POOL_ID });

    if (!USER_POOL_ID) {
      return {
        statusCode: 500,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'USER_POOL_ID env var not set' })
      };
    }

    let username = null;
    try {
      if (event.requestContext && event.requestContext.authorizer && event.requestContext.authorizer.claims) {
        username = event.requestContext.authorizer.claims['cognito:username'] || event.requestContext.authorizer.claims['username'];
      }
    } catch (e) { /* ignore */ }

    if (!username) {
      try {
        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body || {};
        username = body.username || body.user || null;
      } catch (e) {
        console.warn('Failed to parse body', e);
      }
    }

    if (!username) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'username not provided' })
      };
    }

    const params = {
      UserPoolId: USER_POOL_ID,
      Username: username,
      UserAttributes: [
        { Name: 'email_verified', Value: 'true' }
      ]
    };

    try {
      console.log('Calling adminUpdateUserAttributes', { Username: username });
      await cognito.adminUpdateUserAttributes(params).promise();
      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({ ok: true, username })
      };
    } catch (err) {
      console.error('adminUpdateUserAttributes failed', err);
      const status = err && err.statusCode ? err.statusCode : 500;
      return {
        statusCode: status,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: err && err.message ? err.message : 'unknown error', stack: err && err.stack ? err.stack : undefined })
      };
    }
  } catch (topErr) {
    console.error('verify_mail top-level error', topErr);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: topErr.message, stack: topErr.stack })
    };
  }
};
