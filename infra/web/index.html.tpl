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
      <a href="#" id="forgot-link" style="font-size:0.9rem;color:var(--color-secondary);">Forgot password?</a>
     </div>
    <!-- Forgot password workflow -->
    <div id="forgot-container" style="display:none;flex-direction:column;align-items:center;gap:0.5em;">
      <h2>Reset Password</h2>
      <input type="text" id="forgot-username" placeholder="Username" style="padding:0.5em;width:250px;" />
      <button id="send-code-btn" style="padding:0.5em 1em;">Send Code</button>
      <div id="forgot-message" style="color:red;"></div>
      <div id="confirm-reset-container" style="display:none;flex-direction:column;align-items:center;gap:0.5em;">
        <input type="text" id="reset-code" placeholder="Verification Code" style="padding:0.5em;width:250px;" />
        <input type="password" id="reset-new-password" placeholder="New Password" style="padding:0.5em;width:250px;" />
        <button id="confirm-reset-btn" style="padding:0.5em 1em;">Confirm Reset</button>
        <div id="reset-message" style="color:red;"></div>
      </div>
    </div>
    <!-- New password challenge workflow -->
    <div id="new-password-container" style="display:none;flex-direction:column;align-items:center;gap:0.5em;">
      <h2>Set New Password</h2>
      <input type="password" id="new-password" placeholder="New Password" style="padding:0.5em;width:250px;" />
      <input type="password" id="new-password-confirm" placeholder="Confirm Password" style="padding:0.5em;width:250px;" />
      <button id="new-password-btn" style="padding:0.5em 1em;">Set Password</button>
      <div id="newpass-message" style="color:red;"></div>
    </div>
  </main>
  <script>
    // Cognito configuration
    const poolData = {
      UserPoolId: '${user_pool_id}',
      ClientId: '${client_id}'
    };
    const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
    let cognitoUserGlobal;

    document.getElementById('signin-btn').addEventListener('click', () => {
      const username = document.getElementById('username').value;
      const password = document.getElementById('password').value;
      const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({ Username: username, Password: password });
      const userData = { Username: username, Pool: userPool };
      cognitoUserGlobal = new AmazonCognitoIdentity.CognitoUser(userData);
      cognitoUserGlobal.authenticateUser(authDetails, {
        onSuccess: result => {
          const idToken = result.getIdToken().getJwtToken();
          window.location.href = '/dashboard.html#id_token=' + idToken;
        },
        onFailure: err => {
          document.getElementById('signin-message').textContent = err.message;
        },
        newPasswordRequired: (userAttributes, requiredAttributes) => {
          document.querySelector('.login-container').style.display = 'none';
          document.getElementById('new-password-container').style.display = 'flex';
        }
      });
    });
    // New password challenge
    document.getElementById('new-password-btn').addEventListener('click', () => {
      const pass = document.getElementById('new-password').value;
      const confirm = document.getElementById('new-password-confirm').value;
      if (pass !== confirm) {
        document.getElementById('newpass-message').textContent = 'Passwords do not match';
        return;
      }
      cognitoUserGlobal.completeNewPasswordChallenge(pass, {}, {
        onSuccess: result => window.location.reload(),
        onFailure: err => document.getElementById('newpass-message').textContent = err.message
      });
    });
    // Forgot password flow
    document.getElementById('forgot-link').addEventListener('click', e => {
      e.preventDefault();
      document.querySelector('.login-container').style.display = 'none';
      document.getElementById('forgot-container').style.display = 'flex';
    });
    document.getElementById('send-code-btn').addEventListener('click', () => {
      const uname = document.getElementById('forgot-username').value;
      cognitoUserGlobal = new AmazonCognitoIdentity.CognitoUser({ Username: uname, Pool: userPool });
      cognitoUserGlobal.forgotPassword({
        onSuccess: () => document.getElementById('confirm-reset-container').style.display = 'flex',
        onFailure: err => document.getElementById('forgot-message').textContent = err.message
      });
    });
    document.getElementById('confirm-reset-btn').addEventListener('click', () => {
      const code = document.getElementById('reset-code').value;
      const newPass = document.getElementById('reset-new-password').value;
      cognitoUserGlobal.confirmPassword(code, newPass, {
        onSuccess: () => window.location.reload(),
        onFailure: err => document.getElementById('reset-message').textContent = err.message
      });
    });
  </script>
</body>
</html>
