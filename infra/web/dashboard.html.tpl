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
    /* Slide-in menu for managers */
    #slide-menu {
      position: fixed;
      top: 50%;
      transform: translateY(-50%);
      right: 0;
      width: 0;
      overflow: hidden;
      transition: width 0.3s ease;
      background: #f0f0f0;
      border-left: 1px solid #ccc;
      height: 200px;
      box-shadow: -2px 0 5px rgba(0,0,0,0.2);
    }
    #slide-menu.open {
      width: 200px;
    }
    #menu-toggle {
      position: absolute;
      top: 50%;
      left: -20px;
      transform: translateY(-50%) rotate(0deg);
      transition: transform 0.3s ease;
      background: #0073bb;
      color: #fff;
      border: none;
      width: 20px;
      height: 40px;
      cursor: pointer;
    }
    #slide-menu.open #menu-toggle {
      transform: translateY(-50%) rotate(180deg);
    }
    #menu-options {
      display: flex;
      flex-direction: column;
      padding: 10px;
    }
    #menu-options button {
      margin-bottom: 10px;
      padding: 8px;
      font-size: 14px;
      cursor: pointer;
    }
  </style>
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
  <header>
    <div>Dashboard</div>
  <div><a href="${logout_url}" style="color:#fff; text-decoration:none;">Logout</a></div>
  </header>
  <div id="tree-container"></div>
  <!-- sliding manager menu -->
  <div id="slide-menu" style="display:none;">
    <button id="menu-toggle">&#x25C0;</button>
    <div id="menu-options">
      <button id="create-user">Create a new user</button>
      <button id="create-group">Create a group</button>
    </div>
  </div>
  <script>
  const apiEndpoint = "${api_endpoint}";
    const container = document.getElementById("tree-container");
    // calculate dimensions after layout
    const { width, height } = container.getBoundingClientRect();

    // Create SVG canvas with correct dimensions
    const svg = d3.select("#tree-container").append("svg")
      .attr("width", "100%")
      .attr("height", "100%");
    // main group for pan/zoom
    const g = svg.append('g');
    // setup zoom behavior referencing g
    svg.call(
      d3.zoom().scaleExtent([0.5, 2]).on("zoom", (event) => {
        g.attr("transform", event.transform);
      })
    );

    async function loadTree() {
      try {
        console.log("Fetching tree from", apiEndpoint + "/tree");
        const res = await fetch(apiEndpoint + "/tree");
        const data = await res.json();
        console.log("Tree data:", data);
        const root = d3.hierarchy(data);
        // if the current user is a manager, display creation menu
        if (data.is_manager) {
          const menu = document.getElementById('slide-menu');
          menu.style.display = 'block';
          const toggleBtn = document.getElementById('menu-toggle');
          toggleBtn.addEventListener('click', () => {
            menu.classList.toggle('open');
          });
        }
        const treeLayout = d3.tree().size([height, width - 160]);
        treeLayout(root);
        // clear any existing nodes and links
        g.selectAll("*").remove();
        console.log("Rendering nodes:", root.descendants().length);

        // links
        g.selectAll("path.link")
          .data(root.links())
          .enter().append("path")
          .attr("class", "link")
          .attr("fill", "none")
          .attr("stroke", "#555")
          .attr("d", d3.linkHorizontal().x(d => d.y).y(d => d.x));

        // nodes
        const node = g.selectAll("g.node")
          .data(root.descendants())
          .enter().append("g")
          .attr("class", "node")
          .attr("transform", d => "translate(" + d.y + "," + d.x + ")");

        // draw card backgrounds and text fields
        const cardWidth = 200;
        const cardHeight = 80;
        const padding = 10;
        node.append('rect')
          .attr('x', -cardWidth/2)
          .attr('y', -cardHeight/2)
          .attr('width', cardWidth)
          .attr('height', cardHeight)
          .attr('fill', d => d.data.is_manager
            ? 'green'
            : (d.children && d.children.length ? 'red' : 'blue'))
          .attr('rx', 5)
          .attr('ry', 5);
        node.append('text')
          .attr('dy', -cardHeight/2 + padding)
          .style('text-anchor', 'middle')
          .style('font-size', '14px')
          .style('fill', '#fff')
          .text(d => ((d.data.given_name||'') + ' ' + (d.data.family_name||'')).trim());
        node.append('text')
          .attr('dy', -cardHeight/2 + padding + 18)
          .style('text-anchor', 'middle')
          .style('font-size', '12px')
          .style('fill', '#fff')
          .text(d => d.data.username);
        node.append('text')
          .attr('dy', -cardHeight/2 + padding + 34)
          .style('text-anchor', 'middle')
          .style('font-size', '12px')
          .style('fill', '#fff')
          .text(d => 'Groups: ' + (d.data.groups||[]).join(', '));
        node.append('text')
          .attr('dy', -cardHeight/2 + padding + 50)
          .style('text-anchor', 'middle')
          .style('font-size', '12px')
          .style('fill', '#fff')
          .text(d => 'Projects: ' + (d.data.projects||[]).join(', '));
        node.append('text')
          .attr('dy', 30)
          .style('text-anchor', 'middle')
          .style('font-size', '12px')
          .style('fill', '#fff')
          .text(d => 'Manager: ' + (d.data.manager||'None'));
      } catch (e) {
        console.error("Error loading tree:", e);
      }
    }
    loadTree();
  </script>
</body>
</html>
