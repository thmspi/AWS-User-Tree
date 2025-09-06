<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Dashboard - AWS User Tree SPA</title>
  <style>
    body { background-color: black;margin:0; font-family: Arial, sans-serif; display:flex; flex-direction:column; height:100vh; }
  header { padding:1em; background:#0073bb; color:#fff; display:flex; align-items:center; }
  #controls { margin-left:auto; display:flex; align-items:center; gap:0.5em; }
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
    /* outline only the main card on hover */
    .node > rect:hover {
      stroke: #f39c12;
      stroke-width: 2px;
    }
    /* popup delete button */
    .popup-delete {
      cursor: pointer;
    }
  </style>
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
  <header>
    <div>Dashboard</div>
    <div id="controls">
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
  <!-- Create User Modal -->
  <div id="modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); align-items:center; justify-content:center; z-index:2147483648;">
    <div id="modal" style="background:#fff; padding:20px; border-radius:8px; width:320px; box-shadow:0 2px 8px rgba(0,0,0,0.26); position:relative;">
      <h2>Create New User</h2>
      <form id="create-user-form">
        <div style="margin-bottom:10px;">
          <label for="given_name">First Name:</label><br/>
          <input type="text" id="given_name" name="given_name" style="width:100%;"/>
        </div>
        <div style="margin-bottom:10px;">
          <label for="family_name">Last Name:</label><br/>
          <input type="text" id="family_name" name="family_name" style="width:100%;"/>
        </div>
        <div style="margin-bottom:10px;">
          <label for="username">Username:</label><br/>
          <input type="text" id="username" name="username" style="width:100%;"/>
        </div>
        <div style="margin-bottom:10px;">
          <label for="job">Job:</label><br/>
          <input type="text" id="job" name="job" style="width:100%;"/>
        </div>
        <div style="margin-bottom:10px;">
          <label for="team">Team:</label><br/>
          <select id="team" name="team" style="width:100%;"></select>
        </div>
        <div style="margin-bottom:10px;">
          <label for="manager">Manager:</label><br/>
          <select id="manager" name="manager" style="width:100%;"></select>
        </div>
        <div style="margin-bottom:10px;">
          <input type="checkbox" id="is_manager" name="is_manager"/>
          <label for="is_manager">Is Manager</label>
        </div>
        <div style="text-align:right;">
          <button type="button" id="close-modal">Close</button>
          <button type="button" id="save-user">Save</button>
          <button type="button" id="mail-user">Mail</button>
        </div>
      </form>
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
    // separate groups: zoomGroup gets pan/zoom, g is centered content
    const zoomGroup = svg.append('g');
    const g = zoomGroup.append('g');
    // setup zoom behavior referencing g
    svg.call(
      d3.zoom().scaleExtent([0.5, 2]).on("zoom", (event) => {
        // apply pan/zoom to outer group
        zoomGroup.attr("transform", event.transform);
      })
    );

    // position slide-menu below header dynamically
    document.addEventListener('DOMContentLoaded', () => {
      const header = document.querySelector('header');
      const menu = document.getElementById('slide-menu');
      if(header && menu) menu.style.top = header.clientHeight + 'px';
    });
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
        // vertical orientation: width controls x-axis, height controls y-axis
        // use fixed node size: [horizontalSpacing, verticalSpacing]
        const treeLayout = d3.tree().nodeSize([150, 100]);
        treeLayout(root);
        // clear any existing nodes and links
        g.selectAll("*").remove();
        // center the tree: translate g to center horizontally and add top padding
        // center root horizontally
        const xOffset = width / 2;
        // push root down to avoid cropping
        const yOffset = 80;
        // center the tree by translating group
        g.attr("transform", "translate(" + xOffset + "," + yOffset + ")");

        console.log("Rendering nodes:", root.descendants().length);

        // links
        g.selectAll("path.link")
          .data(root.links())
          .enter().append("path")
          .attr("class", "link")
          .attr("fill", "none")
          .attr("stroke", "#555")
          .attr("d", function(d) {
            // vertical tree: x is horizontal, y is depth vertical
            return "M" + d.source.x + "," + d.source.y
              + "C" + (d.source.x + d.target.x) / 2 + "," + d.source.y
              + " " + (d.source.x + d.target.x) / 2 + "," + d.target.y
              + " " + d.target.x + "," + d.target.y;
          });

        // nodes
        const node = g.selectAll("g.node")
          .data(root.descendants())
          .enter().append("g")
          .attr("class", "node")
          // vertical tree: x is horizontal, y is vertical
          .attr("transform", d => "translate(" + d.x + "," + d.y + ")");

        // draw card backgrounds and card text
  const cardWidth = 120;
  const cardHeight = 50;
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
          .attr('text-anchor', 'middle')
          .style('fill', '#fff')
          // use tspan to stack lines
          .selectAll('tspan')
          .data(d => [
            ((d.data.given_name||'') + ' ' + (d.data.family_name||'')).trim(),
            (d.data.job||[]).join(', ')
          ])
          .enter().append('tspan')
            .attr('x', 0)
            .attr('dy', (d,i) => i === 0 ? -(padding/2) : (padding))
            .style('font-size', (d,i) => i === 0 ? '14px' : '12px')
            .text(d => d);
        // on click, toggle detail popup
        node.on('click', function(event, d) {
          // toggle popup: remove existing if present
          const sel = d3.select(this).select('g.popup');
          if (!sel.empty()) { sel.remove(); return; }
          // dynamic popup size and position
          const info = [
            ((d.data.given_name||'')+' '+(d.data.family_name||'')).trim(),
            d.data.username,
            'Job: '+(d.data.job||[]).join(', '),
            'Team: '+(d.data.team||[]).join(', ')
          ];
          const lineHeight = 18;
          const pad = 8;
          const popupWidth = cardWidth + pad*2;
          const popupHeight = info.length * lineHeight + pad*2;
          // create popup group above node
          const popup = d3.select(this).append('g').attr('class','popup')
            // translate up by card half + popup height + margin
            .attr('transform', 'translate(0,' + (-(cardHeight/2) - popupHeight - 5) + ')')
            // clicking popup group closes it
            .on('click', function(e) { d3.select(this).remove(); e.stopPropagation(); });
          // background
          popup.append('rect')
            .attr('x', -popupWidth/2)
            .attr('y', 0)
            .attr('width', popupWidth)
            .attr('height', popupHeight)
            .attr('fill', '#333')
            .attr('rx', 5).attr('ry', 5);
          // text lines
          info.forEach((text,i) => {
            popup.append('text')
              .attr('x', 0)
              .attr('y', pad + (i+1)*lineHeight - lineHeight/2)
              .style('text-anchor','middle')
              .style('fill','#fff')
              .style('font-size','12px')
              .text(text);
          });
        });
      } catch (e) {
        console.error("Error loading tree:", e);
      }
    }
    loadTree();
  </script>
  <script>
    // Utility to generate random password
    function generatePassword() {
      const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const lower = 'abcdefghijklmnopqrstuvwxyz';
      const digits = '0123456789';
      const symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?';
      const all = upper + lower + digits + symbols;
      let pwd = '';
      // ensure each category
      pwd += upper[Math.floor(Math.random() * upper.length)];
      pwd += lower[Math.floor(Math.random() * lower.length)];
      pwd += digits[Math.floor(Math.random() * digits.length)];
      pwd += symbols[Math.floor(Math.random() * symbols.length)];
      // fill to length 12
      for (let i = 4; i < 12; i++) {
        pwd += all[Math.floor(Math.random() * all.length)];
      }
      // shuffle characters
      return pwd.split('').sort(() => Math.random() - 0.5).join('');
    }
    // Main create flow
    async function createUser(sendEmail = false) {
      const form = document.getElementById('create-user-form');
      const username = form.username.value.trim();
      // check username availability
      const availRes = await fetch(apiEndpoint + '/checkavailability', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username })
      });
      const avail = await availRes.json();
      if (!avail.available) {
        alert('Username already taken');
        return;
      }
      const password = generatePassword();
      const userData = {
        username,
        given_name: form.given_name.value,
        family_name: form.family_name.value,
        password,
      };
      try {
        // register in Cognito
        await fetch(apiEndpoint + '/cognito_register', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(userData)
        });
        // store in DynamoDB
        const dynoData = Object.assign({}, userData, {
          job: [form.job.value],
          team: [form.team.value],
          manager: form.manager.value,
          is_manager: form.is_manager.checked
        });
        await fetch(apiEndpoint + '/dynamo_register', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(dynoData)
        });
        // close modal
        document.getElementById('modal-overlay').style.display = 'none';
        const slideMenu = document.getElementById('slide-menu');
        slideMenu.style.pointerEvents = 'auto';
        // ensure menu is closed
        slideMenu.classList.remove('open');
        // notify
        if (sendEmail) {
          alert('Credentials sent via email');
        } else {
          alert('User created\nUsername: ' + username + '\nPassword: ' + password);
        }
        // refresh tree
        loadTree();
      } catch (err) {
        console.error('Error in create flow:', err);
        alert('Error creating user');
      }
    }
    document.getElementById('save-user').addEventListener('click', () => createUser(false));
    document.getElementById('mail-user').addEventListener('click', () => createUser(true));
  </script>
  <!-- initial create-user block removed -->
  <!-- utility and main create flow -->
  <script>
    // Reset form and open Create User modal
    {
      const btnCreate = document.getElementById('create-user');
      const modalOverlay = document.getElementById('modal-overlay');
      const slideMenu = document.getElementById('slide-menu');
      const form = document.getElementById('create-user-form');
      btnCreate.addEventListener('click', async () => {
        form.reset(); // clear previous inputs
         // fetch teams and managers
         try {
           const [teamsRes, managersRes] = await Promise.all([
             fetch(apiEndpoint + '/teams'),
             fetch(apiEndpoint + '/managers')
           ]);
           const teams = await teamsRes.json();
           const managers = await managersRes.json();
           // populate selects
           const teamSel = document.getElementById('team');
           teamSel.innerHTML = '';
           teams.forEach(t => {
             const opt = document.createElement('option'); opt.value = t; opt.textContent = t;
             teamSel.appendChild(opt);
           });
           const mgrSel = document.getElementById('manager');
           mgrSel.innerHTML = '';
           managers.forEach(m => {
             const opt = document.createElement('option'); opt.value = m; opt.textContent = m;
             mgrSel.appendChild(opt);
           });
         } catch (e) {
           console.error('Error loading teams/managers:', e);
         }
         modalOverlay.style.display = 'flex';
         slideMenu.style.pointerEvents = 'none';
      });
      // Close modal
      document.getElementById('close-modal').addEventListener('click', () => {
        modalOverlay.style.display = 'none';
        slideMenu.style.pointerEvents = 'auto';
        // close sliding menu
        slideMenu.classList.remove('open');
      });
    }
  </script>
</body>
</html>
