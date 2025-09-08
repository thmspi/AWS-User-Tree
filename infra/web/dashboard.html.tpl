<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Dashboard - AWS User Tree SPA</title>
  <style>
    :root {
      --color-text: #ccc6c6;
      --color-main: #ef26c6;
      --color-secondary: #a90888;
      --color-black-main: rgb(10 10 10);
      --color-black-secondary: rgb(29 29 29);
    }
    body {
      background-color: var(--color-black-main);
      margin: 0;
      font-family: Arial, sans-serif;
      display: flex;
      flex-direction: column;
      height: 100vh;
      color: var(--color-text);
    }
  header {
    padding: 1em;
    background: var(--color-black-secondary);
    color: var(--color-text);
    display: flex;
    align-items: center;
  }
  #controls { margin-left:auto; display:flex; align-items:center; gap:0.5em; }
    #controls button { margin-left:0.5em; padding:0.5em; font-size:1em; }
    #tree-container {
      flex:1;
      overflow:auto;
      padding:1em;
      margin:1em;
  background: var(--color-black-secondary);
      border-radius: 10px;
      transform-origin:0 0;
      max-width: calc(100% - 2em);
      max-height: calc(100% - 2em - 60px); /* account for header and margin */
    }
    /* Slide-in menu for managers */
    #slide-menu {
      position: fixed;
      top: 60px; /* below header */
      right: 0;
      width: 0; /* closed */
      height: auto;
      pointer-events: auto;
      z-index: 2147483647;
      background: var(--color-black-secondary);
      border-radius: 8px 0 0 8px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      align-items: stretch;
    }
    #slide-menu.open {
      width: auto; /* size to content */
      transition: width 0.3s ease;
    }
    #menu-toggle {
      position: fixed;
      top: calc(60px + 50vh - 20px);
      right: 0;
      transform: translateY(-50%);
      z-index: 2147483648;
      width: 36px;
      height: 36px;
      background: var(--color-main);
      color: var(--color-text);
      border: none;
      border-radius: 4px 0 0 4px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: right 0.3s ease, transform 0.3s ease;
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
    /* Graph styling */
    svg .link { stroke: var(--color-text); }
    .node text { fill: var(--color-text); }
    /* Form and control styling */
    input, select, textarea { 
      background-color: var(--color-black-secondary); 
      color: var(--color-text); 
      border: 1px solid var(--color-secondary); 
      padding: 0.5em;
      border-radius: 4px;
    }
    button {
      background-color: var(--color-secondary);
      color: var(--color-text);
      border: none;
      padding: 0.5em 1em;
      border-radius: 4px;
      cursor: pointer;
    }
    button:hover, input:hover, select:hover, textarea:hover {
      outline: 2px solid var(--color-main);
    }
    button:focus, input:focus, select:focus, textarea:focus {
      outline: 2px solid var(--color-main);
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
      <button id="create-group">Manage Teams</button>
      <button id="delete-user">Delete User</button>
      <button id="switch-manager">Switch Manager</button>
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
        </div>
      </form>
    </div>
  </div>
  <!-- Manage Teams Modal -->
  <div id="team-modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); align-items:center; justify-content:center; z-index:2147483648;">
    <div style="background:#fff; padding:20px; border-radius:8px; width:360px; box-shadow:0 2px 8px rgba(0,0,0,0.26); position:relative;">
      <h2>Manage Teams</h2>
      <ul id="team-list" style="list-style:none; padding:0; max-height:200px; overflow:auto;"></ul>
      <div style="display:flex; gap:8px; margin-top:10px;">
        <input type="text" id="new-team-name" placeholder="Team name" style="flex:1;" />
        <input type="color" id="new-team-color" value="#0073bb" />
        <button type="button" id="add-team-btn">Add</button>
      </div>
      <button type="button" id="close-team-modal" style="position:absolute; top:10px; right:10px;">✕</button>
    </div>
  </div>
  <!-- Delete User Modal -->
  <div id="delete-modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); align-items:center; justify-content:center; z-index:2147483648;">
    <div style="background:#fff; padding:20px; border-radius:8px; width:320px; box-shadow:0 2px 8px rgba(0,0,0,0.26); position:relative;">
      <h2>Delete User</h2>
      <select id="delete-user-select" style="width:100%; margin-bottom:10px;"></select>
      <div style="text-align:right;">
        <button id="cancel-delete">Cancel</button>
        <button id="confirm-delete">Delete</button>
      </div>
    </div>
  </div>
  <!-- Switch Manager Modal -->
  <div id="switch-manager-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); align-items:center; justify-content:center; z-index:2147483648;">
    <div style="background:#fff; padding:20px; border-radius:8px; width:360px; box-shadow:0 2px 8px rgba(0,0,0,0.26); position:relative;">
      <h2>Switch Manager</h2>
      <div style="margin-bottom:10px;">
        <label>Manager A:</label><br>
        <select id="switch-manager-1" style="width:100%;"></select>
      </div>
      <div style="margin-bottom:10px;">
        <label>Manager B:</label><br>
        <select id="switch-manager-2" style="width:100%;"></select>
      </div>
      <div style="text-align:right;">
        <button id="cancel-switch">Cancel</button>
        <button id="confirm-switch">Switch</button>
      </div>
    </div>
  </div>
  <script>
  const apiEndpoint = "${api_endpoint}";
  // parse JWT from URL hash to identify current user
  function parseJwt(token) {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(atob(base64).split('').map(c => '%'+('00'+c.charCodeAt(0).toString(16)).slice(-2)).join(''));
    return JSON.parse(jsonPayload);
  }
  const hashParams = new URLSearchParams(window.location.hash.substr(1));
  const idToken = hashParams.get('id_token');
  const currentUser = idToken ? parseJwt(idToken)['cognito:username'] : null;

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
         // bind menu-toggle click once
     const toggleBtn = document.getElementById('menu-toggle');
     if (toggleBtn) toggleBtn.addEventListener('click', () => {
       document.getElementById('slide-menu').classList.toggle('open');
     });
    });
    async function loadTree() {
      try {
        console.log("Fetching tree from", apiEndpoint + "/tree");
        const res = await fetch(apiEndpoint + "/tree");
        const data = await res.json();
        console.log("Tree data:", data);
        // fetch team color map
        const teamsRes = await fetch(apiEndpoint + '/teams');
        const teamsList = await teamsRes.json();
        const teamColorMap = {};
        teamsList.forEach(t => { teamColorMap[t.name] = t.color; });
        // do not override currentUser; parseJwt used
        const root = d3.hierarchy(data);
        // if the current user is a manager, display creation menu
        if (data.is_manager) {
          document.getElementById('slide-menu').style.display = 'block';
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
          .attr('fill', d => {
            if (d.data.is_manager) return 'green';
            if (d.data.team && d.data.team.length) {
              return teamColorMap[d.data.team[0]] || 'blue';
            }
            if (d.children && d.children.length) return 'red';
            return 'blue';
          })
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
  async function createUser() {

      document.getElementById('modal-overlay').style.display = 'none';
      document.getElementById('menu-options').style.pointerEvents = 'auto';

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
        
    // notify
    alert('User created\nUsername: ' + username + '\nPassword: ' + password);
        // refresh tree
        loadTree();
      } catch (err) {
        console.error('Error in create flow:', err);
        alert('Error creating user');
      }
    }
  document.getElementById('save-user').addEventListener('click', () => createUser());
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
             fetch(apiEndpoint + '/managers?user=' + encodeURIComponent(currentUser))
           ]);
           const teams = await teamsRes.json();
           const managers = await managersRes.json();
           // populate selects
           const teamSel = document.getElementById('team');
           teamSel.innerHTML = '';
           // populate team dropdown with name (and store color)
           teams.forEach(t => {
             const opt = document.createElement('option');
             opt.value = t.name;
             opt.textContent = t.name;
             opt.dataset.color = t.color;
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
         // disable just menu-options, leave toggle active
         document.getElementById('menu-options').style.pointerEvents = 'none';
      });
      // Close modal
      document.getElementById('close-modal').addEventListener('click', () => {
        document.getElementById('modal-overlay').style.display = 'none';
        // re-enable only menu-options
        document.getElementById('menu-options').style.pointerEvents = 'auto';
      });
    }
  </script>
  <script>
    // Manage Teams popup handler
document.addEventListener('DOMContentLoaded', () => {
  const createGroupBtn = document.getElementById('create-group');
  createGroupBtn.addEventListener('click', async () => {
    const overlay = document.getElementById('team-modal-overlay');
    const listEl = document.getElementById('team-list'); listEl.innerHTML = '';
    try {
      const teams = await fetch(apiEndpoint + '/teams').then(r => r.json());
      teams.forEach(t => {
        const li = document.createElement('li');
        const color = t.color || '#0073bb';
  li.innerHTML = `<span style="display:inline-block;width:12px;height:12px;background:$${color};margin-right:8px;"></span>$${t.name}` +
           ` <button data-name="$${t.name}" class="remove-team">-</button>`;
        listEl.appendChild(li);
      });
    } catch(e) { console.error(e); }
    overlay.style.display = 'flex';
  });
});
// Close Manage Teams modal
document.getElementById('close-team-modal').addEventListener('click', () => {
  document.getElementById('team-modal-overlay').style.display = 'none';
});
// Add Team button handler
document.getElementById('add-team-btn').addEventListener('click', async () => {
  const nameInput = document.getElementById('new-team-name');
  const colorInput = document.getElementById('new-team-color');
  const name = nameInput.value.trim();
  const color = colorInput.value;
  if (!name) { alert('Enter team name'); return; }
  try {
    await fetch(apiEndpoint + '/teams', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, color })
    });
    // reload list
    const listEl = document.getElementById('team-list'); listEl.innerHTML = '';
    const teams = await fetch(apiEndpoint + '/teams').then(r => r.json());
    teams.forEach(t => {
      const li = document.createElement('li');
      const clr = t.color || '#0073bb';
      li.innerHTML = `<span style="display:inline-block;width:12px;height:12px;background:$${clr};margin-right:8px;"></span>$${t.name}` +
        ` <button data-name="$${t.name}" class="remove-team">-</button>`;
      listEl.appendChild(li);
    });
    nameInput.value = '';
  } catch (e) {
    console.error('Error adding team:', e);
    alert('Error adding team');
  }
});
  </script>
  <script>
// Delete User popup
const deleteOverlay = document.getElementById('delete-modal-overlay');
const deleteSelect = document.getElementById('delete-user-select');
document.getElementById('delete-user').addEventListener('click', async () => {
  // fetch all users
  try {
    const data = await fetch(apiEndpoint + '/tree').then(r => r.json());
    // find current user node in tree
    function findNode(node, name) {
      if (node.username === name) return node;
      for (const c of node.children || []) {
        const found = findNode(c, name);
        if (found) return found;
      }
      return null;
    }
    const currentNode = findNode(data, currentUser);
    // flatten descendants excluding self
    function flatten(node, arr=[]) {
      for (const c of node.children || []) {
        arr.push(c.username);
        flatten(c, arr);
      }
      return arr;
    }
    const users = currentNode ? flatten(currentNode) : [];
    deleteSelect.innerHTML = '';
    users.forEach(u => {
      const opt = document.createElement('option'); opt.value = u; opt.textContent = u;
      deleteSelect.appendChild(opt);
    });
    deleteOverlay.style.display = 'flex';
  } catch(e) { console.error(e); }
});
// Cancel
document.getElementById('cancel-delete').addEventListener('click', () => {
  deleteOverlay.style.display = 'none';
});
// Confirm delete
document.getElementById('confirm-delete').addEventListener('click', async () => {
  const user = deleteSelect.value;
  deleteOverlay.style.display = 'none';
  try {
    await fetch(apiEndpoint + '/users/' + encodeURIComponent(user), { method: 'DELETE' });
    loadTree();
  } catch(e) { console.error(e); alert('Error deleting user'); }
});
  </script>
  <script>
// Switch Manager popup
const switchOverlay = document.getElementById('switch-manager-overlay');
const sel1 = document.getElementById('switch-manager-1');
const sel2 = document.getElementById('switch-manager-2');
document.getElementById('switch-manager').addEventListener('click', async () => {
  // fetch managers under current user
  try {
    const mgrs = await fetch(apiEndpoint + '/managers?user=' + encodeURIComponent(currentUser)).then(r=>r.json());
    // exclude current user
    const options = mgrs.filter(m => m !== currentUser);
    sel1.innerHTML = '';
    sel2.innerHTML = '';
    options.forEach(m => {
      const o1 = document.createElement('option'); o1.value = m; o1.textContent = m;
      const o2 = document.createElement('option'); o2.value = m; o2.textContent = m;
      sel1.appendChild(o1);
      sel2.appendChild(o2);
    });
  } catch(e){console.error(e)}
  switchOverlay.style.display = 'flex';
});
// Cancel switch
document.getElementById('cancel-switch').addEventListener('click', () => {
  switchOverlay.style.display = 'none';
});
// Confirm switch
document.getElementById('confirm-switch').addEventListener('click', async () => {
  const m1 = sel1.value;
  const m2 = sel2.value;
  if (!m1 || !m2 || m1 === m2) { alert('Select two different managers'); return; }
  switchOverlay.style.display = 'none';
  try {
    await fetch(apiEndpoint + '/switch_manager', {
      method: 'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ managerA: m1, managerB: m2 })
    });
    loadTree();
  } catch(e){ console.error(e); alert('Error switching managers'); }
});
</script>
</body>
</html>
