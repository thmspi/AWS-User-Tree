<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Restricted Access</title>
  <style>
    :root {
      --color-text: #ccc6c6;
      --color-main: rgb(255 180 241);
      --color-secondary: #a90888;
      --color-black-main: rgb(10 10 10);
      --color-black-secondary: rgb(29 29 29);
    }
    body {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: Arial, sans-serif;
      background-color: var(--color-black-main);
      color: var(--color-text);
    }
    h1 {
      font-size: 2rem;
      margin-bottom: 0.5em;
      color: var(--color-text);
    }
    p {
      font-size: 1.2rem;
      margin-bottom: 1.5em;
      color: var(--color-text);
    }
    button {
      padding: 0.75em 1.5em;
      font-size: 1rem;
      border: none;
      background-color: var(--color-secondary);
      color: var(--color-text);
      border-radius: 4px;
      cursor: pointer;
    }
    button:hover, button:focus {
      outline: 2px solid var(--color-main);
    }
  </style>
  <script src="https://sdk.amazonaws.com/js/aws-sdk-2.1500.0.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/amazon-cognito-identity-js@5.2.7/dist/amazon-cognito-identity.min.js"></script>
  <script>
    // Set AWS region for Cognito operations
    AWS.config.region = '${aws_region}';
  </script>
</head>
<body>
  <div class="logo-container" style="display:flex; align-items:center; gap:0.5em; margin-bottom:1em;">
  <img src="/static/sakura_tree.svg" alt="My Org Tree" style="height:32px;" />
    <span style="font-size:1.5rem; color:var(--color-text);">My Org Tree</span>
  </div>
  <main>
    <div class="login-container" style="display:flex;flex-direction:column;align-items:center;gap:1em;">
      <h1>Sign In</h1>
      <input type="text" id="username" placeholder="Username" style="padding:0.5em;width:250px;" />
      <input type="password" id="password" placeholder="Password" style="padding:0.5em;width:250px;" />
      <button id="signin-btn" style="padding:0.5em 1em;background:#ef26c6;color:#fff;border:none;border-radius:4px;cursor:pointer;">Sign In</button>
      <div id="signin-message" style="color:red;"></div>
    </div>
  </main>
  <script>
    // Cognito configuration
    const poolData = {
      UserPoolId: '${user_pool_id}',
      ClientId: '${client_id}'
    };
    const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

    document.getElementById('signin-btn').addEventListener('click', () => {
      const username = document.getElementById('username').value;
      const password = document.getElementById('password').value;
      const authData = { Username: username, Password: password };
      const authDetails = new AmazonCognitoIdentity.AuthenticationDetails(authData);
      const userData = { Username: username, Pool: userPool };
      const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
      cognitoUser.authenticateUser(authDetails, {
        onSuccess: result => {
          // retrieve tokens
          const idToken = result.getIdToken().getJwtToken();
          // redirect to dashboard with token
          window.location.href = '/dashboard.html#id_token=' + idToken;
        },
        onFailure: err => {
          document.getElementById('signin-message').textContent = err.message || JSON.stringify(err);
        }
      });
    });
  </script>
</body>
</html>
