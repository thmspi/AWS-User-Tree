<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AWS User Tree SPA</title>
</head>
<body>
  <h1>Welcome to AWS User Tree SPA</h1>
  <p>If you see this page, the S3 + CloudFront deployment succeeded.</p>
  <div id="app"></div>
  <script>
    document.getElementById('app').innerHTML = '<button onclick="window.location.href=\'${login_url}&client_id=${client_id}\'">Login with Cognito</button>';
  </script>
</body>
</html>
