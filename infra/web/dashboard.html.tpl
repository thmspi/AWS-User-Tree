<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Dashboard - AWS User Tree SPA</title>
  <style>
    body { margin:0; font-family: Arial, sans-serif; display:flex; flex-direction:column; height:100vh; }
    header { padding:1em; background:#0073bb; color:#fff; display:flex; justify-content:space-between; align-items:center; }
    #controls { position:absolute; top:1em; right:1em; }
    #controls button { margin-left:0.5em; padding:0.5em; font-size:1em; }
    #tree-container { flex:1; overflow:auto; padding:1em; transform-origin:0 0; }
    ul.tree { list-style:none; padding-left:1em; }
    ul.tree li { margin:0.5em 0; }
    ul.tree li:before { content:"└─ "; margin-right:0.5em; }
  </style>
</head>
<body>
  <header>
    <div>Dashboard</div>
    <div><a href="${logout_url}" style="color:#fff; text-decoration:none;">Logout</a></div>
  </header>
  <div id="controls">
    <button id="zoom-out">-</button>
    <button id="zoom-in">+</button>
  </div>
  <div id="tree-container"></div>
  <script>
    const apiEndpoint = "${api_endpoint}";
    let scale = 1;
  function updateScale() { document.getElementById('tree-container').style.transform = 'scale(' + scale + ')'; }
    document.getElementById('zoom-in').onclick = () => { scale += 0.1; updateScale(); };
    document.getElementById('zoom-out').onclick = () => { scale = Math.max(0.1, scale - 0.1); updateScale(); };

    // Recursive render of tree as nested UL
    function renderNode(node) {
      const li = document.createElement('li');
      li.textContent = node.username;
      if (node.children && node.children.length) {
        const ul = document.createElement('ul'); ul.className = 'tree';
        node.children.forEach(child => ul.appendChild(renderNode(child)));
        li.appendChild(ul);
      }
      return li;
    }

    async function loadTree() {
      try {
      const res = await fetch(apiEndpoint + '/tree');
        const data = await res.json();
        const container = document.getElementById('tree-container');
        const rootUl = document.createElement('ul'); rootUl.className = 'tree';
        rootUl.appendChild(renderNode(data));
        container.appendChild(rootUl);
      } catch (e) {
        console.error('Failed to load tree:', e);
      }
    }
    loadTree();
  </script>
</body>
</html>
