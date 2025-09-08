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
      --color-main: #ef26c6;
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
</head>
<body>
  <h1>Restricted Access</h1>
  <p>Please login to continue.</p>
  <button onclick="window.location.href='${login_url}'">Login with Cognito</button>
</body>
</html>
