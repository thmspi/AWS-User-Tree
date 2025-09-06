<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Dashboard - AWS User Tree SPA</title>
  <style>
    body { background-color: black;margin:0; font-family: Arial, sans-serif; display:flex; flex-direction:column; height:100vh; }
    header { padding:1em; background:#0073bb; color:#fff; display:flex; justify-content:space-between; align-items:center; }
    #controls { position:absolute; top:1em; right:1em; }
    #controls button { margin-left:0.5em; padding:0.5em; font-size:1em; }
    #tree-container {
      flex:1;
      overflow:auto;
      padding:1em;
      margin:1em;
      background: #fff;
      border-radius: 10px;
      transform-origin:0 0;
      max-width: calc(100% - 2em);
      max-height: calc(100% - 2em - 60px); /* account for header and margin */
    }
    /* Slide-in menu for managers */
    #slide-menu {
      position: fixed;
      top: 60px; /* slide down below the header bar */
      right: 0;
      width: 0;  /* fully closed by default */
      height: calc(100vh - 60px); /* full height minus header */
      overflow: visible;
      pointer-events: auto;
      z-index: 2147483647; /* topmost */
      background: #f0f0f0;
      border-left: 1px solid #ccc;
      /* remove translateY for full-height panel */
    }
    #slide-menu.open {
      width: 200px;
      transition: width 0.3s ease;
    }
    #menu-toggle {
      /* Make toggle fixed to viewport edge */
      position: fixed;
      top: calc(60px + 50vh - 20px); /* below header, centered */
      right: 0;
      transform: translateY(-50%);
      z-index: 2147483648;
      pointer-events: auto;
      width: 20px;
      height: 40px;
      background: #eee;
      color: #333;
      border: 1px solid #ccc;
      text-align: center;
      line-height: 40px;
      opacity: 1;  /* ensure the toggle is always visible */
      transition: right 0.3s ease, opacity 0.3s ease;
    }
    #slide-menu.open #menu-toggle {
      /* move toggle right by menu width when open */
      right: 200px;
      opacity: 1;
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
    /* outline card on hover */
    .node rect:hover {
      stroke: #f39c12;
      stroke-width: 2px;
    }
  </style>
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
  <header>
    <div>Dashboard</div>
    <div id="controls">
      <button id="open-aws-console" style="margin-right:0.5em;">AWS Console</button>
      <a href="${logout_url}" style="color:#fff; text-decoration:none;">Logout</a>
    </div>
  </header>
  <div id="tree-container"></div>
  <!-- sliding manager menu -->
  <div id="slide-menu">
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
      .attr("width", "97%")
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
        // center the tree: translate g to center horizontally and add top padding
        const xOffset = (width - 160) / 2;
        const yOffset = 20;
        // center the tree by translating group
        g.attr("transform", "translate(" + xOffset + "," + yOffset + ")");

        console.log("Rendering nodes:", root.descendants().length);

        // open AWS console button handler
        document.getElementById('open-aws-console').onclick = () => window.open('https://eu-west-3.console.aws.amazon.com/console/home?region=eu-west-3', '_blank');
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

        // draw card backgrounds and text fields (initial: name & job)
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
        // show only name and job
        node.append('text')
          .attr('dy', -cardHeight/2 + padding + 18)
          .style('text-anchor', 'middle')
          .style('font-size', '12px')
          .style('fill', '#fff')
          .text(d => (d.data.job||[]).join(', '));
        // on click, toggle detail popup
        node.on('click', function(event, d) {
          const sel = d3.select(this).select('g.popup');
          if (!sel.empty()) { sel.remove(); return; }
          const popup = d3.select(this).append('g').attr('class','popup')
            .attr('transform', 'translate(0,' + (-cardHeight/2 - 10) + ')');
          // background
          popup.append('rect')
            .attr('x', -cardWidth/2)
            .attr('y', - (cardHeight + 10))
            .attr('width', cardWidth)
            .attr('height', cardHeight + 20)
            .attr('fill', '#333')
            .attr('rx', 5).attr('ry',5);
          // details lines
          const info = [
            ((d.data.given_name||'')+' '+(d.data.family_name||'')).trim(),
            d.data.username,
            'Job: '+(d.data.job||[]).join(', '),
            'Team: '+(d.data.team||[]).join(', ')
          ];
          info.forEach((text,i) => {
            popup.append('text')
              .attr('x', 0)
              .attr('y', -cardHeight - 10 + 20 + i*18)
              .style('text-anchor','middle')
              .style('fill','#fff')
              .style('font-size','12px')
              .text(text);
          });
          // action buttons
          const btnY = 0;
          // Delete
          popup.append('rect')
            .attr('x', -cardWidth/2 + 10)
            .attr('y', btnY)
            .attr('width', 60)
            .attr('height',20)
            .attr('fill','#e74c3c')
            .attr('rx',3);
          popup.append('text')
            .attr('x', -cardWidth/2 + 10 + 30)
            .attr('y', btnY + 14)
            .style('text-anchor','middle')
            .style('fill','#fff')
            .style('font-size','12px')
            .text('Delete');
          // Create
          popup.append('rect')
            .attr('x', cardWidth/2 - 70)
            .attr('y', btnY)
            .attr('width', 60)
            .attr('height',20)
            .attr('fill','#27ae60')
            .attr('rx',3);
          popup.append('text')
            .attr('x', cardWidth/2 - 70 + 30)
            .attr('y', btnY + 14)
            .style('text-anchor','middle')
            .style('fill','#fff')
            .style('font-size','12px')
            .text('Create');
        });
      } catch (e) {
        console.error("Error loading tree:", e);
      }
    }
    loadTree();
  </script>
</body>
</html>
