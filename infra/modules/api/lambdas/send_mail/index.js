// Lambda to send email with new user credentials via SES
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const ses = new SESClient({});

exports.handler = async (event) => {
  let body;
  try {
    body = JSON.parse(event.body);
  } catch (err) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON' }) };
  }

  const { given_name, family_name, username, password, email } = body;
  const sourceEmail = process.env.SES_SOURCE_EMAIL;
  const loginUrl = process.env.LOGIN_URL;

  if (!email || !sourceEmail || !loginUrl) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing required parameters' }) };
  }

  const message = `Hello ${given_name} ${family_name},\n\n` +
    `Your account has been created.\n` +
    `Username: ${username}\n` +
    `Password: ${password}\n\n` +
    `You can log in at: ${loginUrl}\n` +
    `Please change your password upon first login.\n`;

  try {
    await ses.send(new SendEmailCommand({
      Source: sourceEmail,
      Destination: { ToAddresses: [email] },
      Message: {
        Subject: { Data: 'Your New Account Credentials' },
        Body: { Text: { Data: message } }
      }
    }));

    return { statusCode: 200, body: JSON.stringify({ message: 'Email sent' }) };
  } catch (err) {
    console.error('Error sending email:', err);
    return { statusCode: err.$metadata?.httpStatusCode || 500, body: JSON.stringify({ message: err.message }) };
  }
};
