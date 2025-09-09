// Lambda: verify_mail
// Purpose: mark user's email as verified in Cognito using AdminUpdateUserAttributes
// Expected environment variables:
//   USER_POOL_ID - the Cognito User Pool ID
// Invocation:
//  - POST JSON body { "username": "..." }
//  - or, if behind a Cognito authorizer, username will be taken from event.requestContext.authorizer.claims['cognito:username']

const { CognitoIdentityProviderClient, AdminUpdateUserAttributesCommand } = require('@aws-sdk/client-cognito-identity-provider');
const cognito = new CognitoIdentityProviderClient({});

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
    // Log incoming event for debugging
    try { console.log('event:', JSON.stringify(event)); } catch (e) { console.log('event (non-serializable)'); }

    if (!USER_POOL_ID) {
      const resp = { error: 'USER_POOL_ID env var not set' };
      if (event && event.headers && (event.headers['x-debug'] === '1' || event.headers['X-Debug'] === '1')) resp._debug = { eventSample: event };
      return {
        statusCode: 500,
        headers: CORS_HEADERS,
        body: JSON.stringify(resp)
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
      const resp = { error: 'username not provided' };
      if (event && event.headers && (event.headers['x-debug'] === '1' || event.headers['X-Debug'] === '1')) resp._debug = { eventSample: event };
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify(resp)
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
      console.log('Calling AdminUpdateUserAttributes', { Username: username });
      const cmd = new AdminUpdateUserAttributesCommand(params);
      await cognito.send(cmd);
      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({ ok: true, username })
      };
    } catch (err) {
      console.error('AdminUpdateUserAttributes failed', err);
      const status = err && err.$metadata && err.$metadata.httpStatusCode ? err.$metadata.httpStatusCode : 500;
      const resp = { error: err && err.message ? err.message : 'unknown error', stack: err && err.stack ? err.stack : undefined };
      if (event && event.headers && (event.headers['x-debug'] === '1' || event.headers['X-Debug'] === '1')) resp._debug = { eventSample: event };
      return {
        statusCode: status,
        headers: CORS_HEADERS,
        body: JSON.stringify(resp)
      };
    }
  } catch (topErr) {
    console.error('verify_mail top-level error', topErr);
    const resp = { error: topErr.message, stack: topErr.stack };
    if (event && event.headers && (event.headers['x-debug'] === '1' || event.headers['X-Debug'] === '1')) resp._debug = { eventSample: event };
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify(resp)
    };
  }
};
