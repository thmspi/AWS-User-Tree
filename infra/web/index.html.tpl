<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Restricted Access</title>
  <style>
    body {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: Arial, sans-serif;
      background-color: #f5f5f5;
      color: #333;
    }
    h1 {
      font-size: 2rem;
      margin-bottom: 0.5em;
    }
    p {
      font-size: 1.2rem;
      margin-bottom: 1.5em;
    }
    button {
      padding: 0.75em 1.5em;
      font-size: 1rem;
      border: none;
      background-color: #0073bb;
      color: #fff;
      border-radius: 4px;
      cursor: pointer;
    }
    button:hover {
      background-color: #005fa3;
    }
  </style>
</head>
<body>
  <h1>Restricted Access</h1>
  <p>Please login to continue.</p>
  <button onclick="window.location.href='${login_url}'">Login with Cognito</button>
</body>
</html>
