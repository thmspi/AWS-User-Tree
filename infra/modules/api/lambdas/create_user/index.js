// Lambda to handle user creation: Cognito user, DynamoDB entry, SNS notification
const { CognitoIdentityProviderClient, AdminCreateUserCommand, AdminSetUserPasswordCommand } = require('@aws-sdk/client-cognito-identity-provider');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const crypto = require('crypto');

const cognitoClient = new CognitoIdentityProviderClient({});
const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);
const snsClient = new SNSClient({});

exports.handler = async (event) => {
  console.log('CreateUser event:', event);
  try {
    const body = JSON.parse(event.body || '{}');
    const { given_name, family_name, email, manager, team = [], job = [], permissions = [], is_manager=false } = body;

    // generate random password
    const password = crypto.randomBytes(8).toString('base64');

    // create user in Cognito User Pool
    const userPoolId = process.env.USER_POOL_ID;
    const createCmd = new AdminCreateUserCommand({
      UserPoolId: userPoolId,
      Username: email,
      TemporaryPassword: password,
      UserAttributes: [
        { Name: 'given_name', Value: given_name },
        { Name: 'family_name', Value: family_name },
        { Name: 'email', Value: email },
        { Name: 'email_verified', Value: 'true' }
      ]
    });
    await cognitoClient.send(createCmd);

    // set permanent password
    const setPwdCmd = new AdminSetUserPasswordCommand({
      UserPoolId: userPoolId,
      Username: email,
      Password: password,
      Permanent: true
    });
    await cognitoClient.send(setPwdCmd);

    // put item in DynamoDB
    const tableName = process.env.TABLE_NAME;
    const putCmd = new PutCommand({
      TableName: tableName,
      Item: {
        username: email,
        given_name,
        family_name,
        email,
        manager: manager || null,
        level: 1,
        team,
        job,
        permissions,
        is_manager
      }
    });
    await docClient.send(putCmd);

    // publish SNS notification
    const topicArn = process.env.SNS_TOPIC_ARN;
    const msg = `A new user has been created:\nEmail: ${email}\nPassword: ${password}`;
    const pubCmd = new PublishCommand({
      TopicArn: topicArn,
      Message: msg,
      Subject: 'New User Created'
    });
    await snsClient.send(pubCmd);

    // respond with credentials
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Access-Control-Allow-Headers': '*'
      },
      body: JSON.stringify({ email, password })
    };
  } catch (err) {
    console.error('Error creating user:', err);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      body: JSON.stringify({ message: err.message })
    };
  }
};
