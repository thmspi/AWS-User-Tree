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
  </style>
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
  <header>
    <div>Dashboard</div>
    <div><a href="${logout_url}" style="color:#fff; text-decoration:none;">Logout</a></div>
  </header>
  <div id="tree-container"></div>
  <script>
    const apiEndpoint = "${api_endpoint}";
    const container = document.getElementById('tree-container');
    const width = container.clientWidth;
    const height = container.clientHeight;

    // Create SVG canvas
    const svg = d3.select('#tree-container').append('svg')
      .attr('width', width)
      .attr('height', height)
      .call(d3.zoom().scaleExtent([0.5, 2]).on('zoom', (event) => {
        g.attr('transform', event.transform);
      }));
    const g = svg.append('g');

    async function loadTree() {
      try {
        console.log('Fetching tree from', apiEndpoint + '/tree');
        const res = await fetch(apiEndpoint + '/tree');
        const data = await res.json();
        console.log('Tree data:', data);
        const root = d3.hierarchy(data);
        const treeLayout = d3.tree().size([height, width - 160]);
        treeLayout(root);

        // links
        g.selectAll('path.link')
          .data(root.links())
          .enter().append('path')
          .attr('class', 'link')
          .attr('fill', 'none')
          .attr('stroke', '#555')
          .attr('d', d3.linkHorizontal().x(d => d.y).y(d => d.x));

        // nodes
        const node = g.selectAll('g.node')
          .data(root.descendants())
          .enter().append('g')
          .attr('class', 'node')
          .attr('transform', d => `translate($${d.y},$${d.x})`);

        node.append('circle')
          .attr('r', 6)
          .attr('fill', d => d.children ? '#555' : '#999');

        node.append('text')
          .attr('dy', 3)
          .attr('x', d => d.children ? -10 : 10)
          .style('text-anchor', d => d.children ? 'end' : 'start')
          .text(d => d.data.username);
      } catch (e) {
        console.error('Error loading tree:', e);
      }
    }
    loadTree();
  </script>
</body>
</html>
