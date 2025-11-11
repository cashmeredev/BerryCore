#!/usr/bin/env python3
"""
BerrySnip - Snippet & Notes Manager for BlackBerry 10 / BerryCore
A dual-interface app for managing code snippets and notes

Interfaces:
  - Web Server (ES5 compliant) on port 8018
  - TUI (ncurses) with yank clipboard integration

Usage:
  ./app.py web       - Start web server (default)
  ./app.py tui       - Start TUI interface
  ./app.py add       - Quick add snippet (TUI)
  ./app.py list      - List all snippets
  ./app.py help      - Show help
"""

import sys
import os
import json
import sqlite3
import subprocess
import signal
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

# Configuration
DATA_DIR = os.path.expanduser("~/.berrysnip")
DB_PATH = os.path.join(DATA_DIR, "snippets.db")
PORT = 8018

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)

# ============================================================================
# Database Layer
# ============================================================================

def init_db():
    """Initialize SQLite database with snippets table"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS snippets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            language TEXT,
            tags TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_title ON snippets(title)
    """)
    
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_created ON snippets(created_at DESC)
    """)
    
    conn.commit()
    conn.close()

def get_snippets(search=None, tag=None):
    """Get all snippets, optionally filtered by search term or tag"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    query = "SELECT * FROM snippets WHERE 1=1"
    params = []
    
    if search:
        query += " AND (title LIKE ? OR content LIKE ? OR tags LIKE ?)"
        search_term = f"%{search}%"
        params.extend([search_term, search_term, search_term])
    
    if tag:
        query += " AND tags LIKE ?"
        params.append(f"%{tag}%")
    
    query += " ORDER BY updated_at DESC"
    
    cursor.execute(query, params)
    snippets = [dict(row) for row in cursor.fetchall()]
    conn.close()
    
    return snippets

def get_snippet(snippet_id):
    """Get a single snippet by ID"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM snippets WHERE id = ?", (snippet_id,))
    snippet = cursor.fetchone()
    conn.close()
    
    return dict(snippet) if snippet else None

def add_snippet(title, content, language="", tags=""):
    """Add a new snippet"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO snippets (title, content, language, tags)
        VALUES (?, ?, ?, ?)
    """, (title, content, language, tags))
    
    snippet_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    return snippet_id

def update_snippet(snippet_id, title, content, language="", tags=""):
    """Update an existing snippet"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("""
        UPDATE snippets 
        SET title = ?, content = ?, language = ?, tags = ?,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    """, (title, content, language, tags, snippet_id))
    
    conn.commit()
    conn.close()

def delete_snippet(snippet_id):
    """Delete a snippet"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM snippets WHERE id = ?", (snippet_id,))
    
    conn.commit()
    conn.close()

def get_all_tags():
    """Get all unique tags from snippets"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("SELECT DISTINCT tags FROM snippets WHERE tags != ''")
    rows = cursor.fetchall()
    conn.close()
    
    tags = set()
    for row in rows:
        if row[0]:
            for tag in row[0].split(","):
                tags.add(tag.strip())
    
    return sorted(list(tags))

# ============================================================================
# Web Server (ES5 Compliant)
# ============================================================================

class SnippetHandler(BaseHTTPRequestHandler):
    """HTTP request handler for snippet management"""
    
    def log_message(self, format, *args):
        """Custom logging"""
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))
    
    def send_json(self, data, status=200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def send_html(self, html, status=200):
        """Send HTML response"""
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode())
    
    def do_GET(self):
        """Handle GET requests"""
        parsed = urlparse(self.path)
        path = parsed.path
        
        if path == "/" or path == "/index.html":
            self.send_html(get_main_html())
        elif path == "/api/snippets":
            params = parse_qs(parsed.query)
            search = params.get("search", [None])[0]
            tag = params.get("tag", [None])[0]
            snippets = get_snippets(search=search, tag=tag)
            self.send_json({"snippets": snippets})
        elif path.startswith("/api/snippet/"):
            snippet_id = path.split("/")[-1]
            snippet = get_snippet(snippet_id)
            if snippet:
                self.send_json(snippet)
            else:
                self.send_json({"error": "Snippet not found"}, 404)
        elif path == "/api/tags":
            tags = get_all_tags()
            self.send_json({"tags": tags})
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests"""
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode()
        
        parsed = urlparse(self.path)
        path = parsed.path
        
        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            self.send_json({"error": "Invalid JSON"}, 400)
            return
        
        if path == "/api/snippets":
            snippet_id = add_snippet(
                data.get("title", "Untitled"),
                data.get("content", ""),
                data.get("language", ""),
                data.get("tags", "")
            )
            self.send_json({"id": snippet_id, "success": True})
        elif path.startswith("/api/snippet/") and path.endswith("/update"):
            snippet_id = path.split("/")[-2]
            update_snippet(
                snippet_id,
                data.get("title", "Untitled"),
                data.get("content", ""),
                data.get("language", ""),
                data.get("tags", "")
            )
            self.send_json({"success": True})
        elif path.startswith("/api/snippet/") and path.endswith("/delete"):
            snippet_id = path.split("/")[-2]
            delete_snippet(snippet_id)
            self.send_json({"success": True})
        else:
            self.send_json({"error": "Not found"}, 404)

def get_main_html():
    """Return main HTML page (ES5 compliant for BlackBerry browser)"""
    return """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BerrySnip - Snippet Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: Arial, sans-serif;
            background: #1a1a1a;
            color: #e0e0e0;
            padding: 10px;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 24px;
            color: white;
        }
        
        .controls {
            background: #2a2a2a;
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 15px;
        }
        
        .search-box {
            width: 100%;
            padding: 10px;
            background: #3a3a3a;
            border: 1px solid #555;
            color: #e0e0e0;
            border-radius: 5px;
            font-size: 14px;
            margin-bottom: 10px;
        }
        
        .btn {
            padding: 10px 15px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            margin-right: 5px;
            margin-bottom: 5px;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-success {
            background: #48bb78;
            color: white;
        }
        
        .btn-danger {
            background: #f56565;
            color: white;
        }
        
        .btn-secondary {
            background: #4a5568;
            color: white;
        }
        
        .snippet-list {
            background: #2a2a2a;
            border-radius: 8px;
            padding: 10px;
        }
        
        .snippet-item {
            background: #3a3a3a;
            border-left: 4px solid #667eea;
            padding: 10px;
            margin-bottom: 10px;
            border-radius: 4px;
            cursor: pointer;
        }
        
        .snippet-item:hover {
            background: #454545;
        }
        
        .snippet-title {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 5px;
            color: #667eea;
        }
        
        .snippet-preview {
            color: #a0a0a0;
            font-size: 12px;
            overflow: hidden;
            white-space: nowrap;
            text-overflow: ellipsis;
        }
        
        .snippet-meta {
            font-size: 11px;
            color: #808080;
            margin-top: 5px;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.8);
            z-index: 1000;
            overflow: auto;
        }
        
        .modal-content {
            background: #2a2a2a;
            margin: 20px auto;
            padding: 20px;
            max-width: 600px;
            border-radius: 8px;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #b0b0b0;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 8px;
            background: #3a3a3a;
            border: 1px solid #555;
            color: #e0e0e0;
            border-radius: 4px;
            font-family: monospace;
        }
        
        .form-group textarea {
            min-height: 200px;
            font-family: 'Courier New', monospace;
        }
        
        .tags {
            margin-top: 5px;
        }
        
        .tag {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 11px;
            margin-right: 5px;
        }
        
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #808080;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
            color: #808080;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🍇 BerrySnip</h1>
        <p>Snippet & Notes Manager</p>
    </div>
    
    <div class="controls">
        <input type="text" class="search-box" id="searchBox" placeholder="Search snippets...">
        <button class="btn btn-success" onclick="showAddModal()">+ Add Snippet</button>
        <button class="btn btn-secondary" onclick="loadSnippets()">🔄 Refresh</button>
        <button class="btn btn-secondary" onclick="showTags()">🏷️ Tags</button>
    </div>
    
    <div class="snippet-list" id="snippetList">
        <div class="loading">Loading snippets...</div>
    </div>
    
    <!-- Add/Edit Modal -->
    <div class="modal" id="snippetModal">
        <div class="modal-content">
            <h2 id="modalTitle">Add Snippet</h2>
            <form id="snippetForm">
                <div class="form-group">
                    <label>Title</label>
                    <input type="text" id="snippetTitle" required>
                </div>
                <div class="form-group">
                    <label>Language</label>
                    <input type="text" id="snippetLanguage" placeholder="e.g., python, javascript, bash">
                </div>
                <div class="form-group">
                    <label>Tags (comma-separated)</label>
                    <input type="text" id="snippetTags" placeholder="e.g., code, script, utility">
                </div>
                <div class="form-group">
                    <label>Content</label>
                    <textarea id="snippetContent" required></textarea>
                </div>
                <button type="submit" class="btn btn-success">Save</button>
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
            </form>
        </div>
    </div>
    
    <!-- View Modal -->
    <div class="modal" id="viewModal">
        <div class="modal-content">
            <h2 id="viewTitle"></h2>
            <div id="viewMeta"></div>
            <div class="form-group">
                <label>Content</label>
                <textarea id="viewContent" readonly></textarea>
            </div>
            <button class="btn btn-primary" onclick="editSnippet()">✏️ Edit</button>
            <button class="btn btn-danger" onclick="deleteSnippet()">🗑️ Delete</button>
            <button class="btn btn-secondary" onclick="closeViewModal()">Close</button>
        </div>
    </div>
    
    <script>
        // ES5 compatible JavaScript
        var currentSnippetId = null;
        
        // Load snippets on page load
        window.onload = function() {
            loadSnippets();
        };
        
        // Search functionality
        document.getElementById('searchBox').onkeyup = function() {
            var searchTerm = this.value;
            if (searchTerm.length >= 2 || searchTerm.length === 0) {
                loadSnippets(searchTerm);
            }
        };
        
        function loadSnippets(search) {
            var url = '/api/snippets';
            if (search) {
                url += '?search=' + encodeURIComponent(search);
            }
            
            fetch(url)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    displaySnippets(data.snippets);
                })
                .catch(function(error) {
                    document.getElementById('snippetList').innerHTML = 
                        '<div class="empty-state">Error loading snippets</div>';
                });
        }
        
        function displaySnippets(snippets) {
            var listEl = document.getElementById('snippetList');
            
            if (snippets.length === 0) {
                listEl.innerHTML = '<div class="empty-state">No snippets found.<br>Click "Add Snippet" to create your first one!</div>';
                return;
            }
            
            var html = '';
            for (var i = 0; i < snippets.length; i++) {
                var snippet = snippets[i];
                var preview = snippet.content.substring(0, 100).replace(/</g, '&lt;').replace(/>/g, '&gt;');
                var tags = snippet.tags ? snippet.tags.split(',') : [];
                var tagsHtml = '';
                
                for (var j = 0; j < tags.length; j++) {
                    if (tags[j].trim()) {
                        tagsHtml += '<span class="tag">' + tags[j].trim() + '</span>';
                    }
                }
                
                html += '<div class="snippet-item" onclick="viewSnippet(' + snippet.id + ')">';
                html += '<div class="snippet-title">' + escapeHtml(snippet.title) + '</div>';
                html += '<div class="snippet-preview">' + preview + '</div>';
                html += '<div class="snippet-meta">';
                if (snippet.language) {
                    html += '📝 ' + snippet.language + ' | ';
                }
                html += '🕐 ' + formatDate(snippet.updated_at);
                html += '</div>';
                if (tagsHtml) {
                    html += '<div class="tags">' + tagsHtml + '</div>';
                }
                html += '</div>';
            }
            
            listEl.innerHTML = html;
        }
        
        function showAddModal() {
            currentSnippetId = null;
            document.getElementById('modalTitle').textContent = 'Add Snippet';
            document.getElementById('snippetTitle').value = '';
            document.getElementById('snippetLanguage').value = '';
            document.getElementById('snippetTags').value = '';
            document.getElementById('snippetContent').value = '';
            document.getElementById('snippetModal').style.display = 'block';
        }
        
        function closeModal() {
            document.getElementById('snippetModal').style.display = 'none';
        }
        
        function closeViewModal() {
            document.getElementById('viewModal').style.display = 'none';
        }
        
        function viewSnippet(id) {
            fetch('/api/snippet/' + id)
                .then(function(response) { return response.json(); })
                .then(function(snippet) {
                    currentSnippetId = snippet.id;
                    document.getElementById('viewTitle').textContent = snippet.title;
                    document.getElementById('viewContent').value = snippet.content;
                    
                    var meta = '';
                    if (snippet.language) {
                        meta += '📝 Language: ' + snippet.language + ' | ';
                    }
                    if (snippet.tags) {
                        meta += '🏷️ Tags: ' + snippet.tags + ' | ';
                    }
                    meta += '🕐 Updated: ' + formatDate(snippet.updated_at);
                    
                    document.getElementById('viewMeta').innerHTML = '<div class="snippet-meta">' + meta + '</div>';
                    document.getElementById('viewModal').style.display = 'block';
                });
        }
        
        function editSnippet() {
            if (!currentSnippetId) return;
            
            fetch('/api/snippet/' + currentSnippetId)
                .then(function(response) { return response.json(); })
                .then(function(snippet) {
                    document.getElementById('modalTitle').textContent = 'Edit Snippet';
                    document.getElementById('snippetTitle').value = snippet.title;
                    document.getElementById('snippetLanguage').value = snippet.language || '';
                    document.getElementById('snippetTags').value = snippet.tags || '';
                    document.getElementById('snippetContent').value = snippet.content;
                    closeViewModal();
                    document.getElementById('snippetModal').style.display = 'block';
                });
        }
        
        function deleteSnippet() {
            if (!currentSnippetId) return;
            
            if (confirm('Delete this snippet?')) {
                fetch('/api/snippet/' + currentSnippetId + '/delete', {
                    method: 'POST'
                })
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        closeViewModal();
                        loadSnippets();
                    }
                });
            }
        }
        
        function showTags() {
            fetch('/api/tags')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.tags.length > 0) {
                        alert('Available tags:\\n' + data.tags.join(', '));
                    } else {
                        alert('No tags found');
                    }
                });
        }
        
        // Form submission
        document.getElementById('snippetForm').onsubmit = function(e) {
            e.preventDefault();
            
            var data = {
                title: document.getElementById('snippetTitle').value,
                language: document.getElementById('snippetLanguage').value,
                tags: document.getElementById('snippetTags').value,
                content: document.getElementById('snippetContent').value
            };
            
            var url = currentSnippetId ? 
                '/api/snippet/' + currentSnippetId + '/update' : 
                '/api/snippets';
            
            fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            })
            .then(function(response) { return response.json(); })
            .then(function(result) {
                if (result.success || result.id) {
                    closeModal();
                    loadSnippets();
                }
            });
            
            return false;
        };
        
        function escapeHtml(text) {
            var div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function formatDate(dateStr) {
            var date = new Date(dateStr);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        }
    </script>
</body>
</html>"""

def start_web_server():
    """Start the HTTP server"""
    init_db()
    
    server = HTTPServer(("0.0.0.0", PORT), SnippetHandler)
    
    print(f"╔{'═' * 60}╗")
    print(f"║{' ' * 60}║")
    print(f"║  🍇 BerrySnip Web Server Started{' ' * 27}║")
    print(f"║{' ' * 60}║")
    print(f"║  Access at: http://127.0.0.1:{PORT:<5}{' ' * 30}║")
    print(f"║  Press Ctrl+C to stop{' ' * 37}║")
    print(f"║{' ' * 60}║")
    print(f"╚{'═' * 60}╝")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        server.shutdown()

# ============================================================================
# TUI Interface (ncurses)
# ============================================================================

def tui_interface():
    """Terminal User Interface for snippet management"""
    try:
        import curses
    except ImportError:
        print("Error: curses module not available")
        sys.exit(1)
    
    init_db()
    
    def main(stdscr):
        curses.curs_set(0)
        stdscr.nodelay(0)
        stdscr.keypad(True)
        
        # Initialize colors
        curses.start_color()
        curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK)
        curses.init_pair(4, curses.COLOR_RED, curses.COLOR_BLACK)
        curses.init_pair(5, curses.COLOR_MAGENTA, curses.COLOR_BLACK)
        
        selected = 0
        search_term = ""
        
        while True:
            stdscr.clear()
            height, width = stdscr.getmaxyx()
            
            # Header
            header = "🍇 BerrySnip - Snippet Manager"
            stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
            stdscr.addstr(0, (width - len(header)) // 2, header)
            stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)
            
            # Search bar
            stdscr.attron(curses.color_pair(3))
            stdscr.addstr(2, 2, f"Search: {search_term}_")
            stdscr.attroff(curses.color_pair(3))
            
            # Load snippets
            snippets = get_snippets(search=search_term if search_term else None)
            
            # Display snippets
            start_row = 4
            visible_rows = height - start_row - 3
            
            if not snippets:
                stdscr.attron(curses.color_pair(3))
                msg = "No snippets found. Press 'a' to add one."
                stdscr.addstr(start_row + 5, (width - len(msg)) // 2, msg)
                stdscr.attroff(curses.color_pair(3))
            else:
                for idx, snippet in enumerate(snippets[:visible_rows]):
                    row = start_row + idx
                    
                    if idx == selected:
                        stdscr.attron(curses.color_pair(2) | curses.A_REVERSE)
                    
                    # Truncate title if too long
                    title = snippet['title']
                    if len(title) > width - 10:
                        title = title[:width-13] + "..."
                    
                    stdscr.addstr(row, 2, f"{idx+1:2d}. {title}")
                    
                    if idx == selected:
                        stdscr.attroff(curses.color_pair(2) | curses.A_REVERSE)
            
            # Footer with commands
            footer_row = height - 2
            stdscr.attron(curses.color_pair(5))
            commands = "[↑↓]Nav [Enter]View [a]Add [e]Edit [d]Del [y]Yank [/]Search [q]Quit"
            stdscr.addstr(footer_row, 2, commands[:width-4])
            stdscr.attroff(curses.color_pair(5))
            
            stdscr.refresh()
            
            # Handle input
            key = stdscr.getch()
            
            if key == ord('q'):
                break
            elif key == curses.KEY_UP and selected > 0:
                selected -= 1
            elif key == curses.KEY_DOWN and snippets and selected < min(len(snippets)-1, visible_rows-1):
                selected += 1
            elif key == ord('a'):
                curses.endwin()
                add_snippet_tui()
                stdscr = curses.initscr()
                curses.curs_set(0)
                stdscr.keypad(True)
                selected = 0
            elif key == ord('e') and snippets:
                curses.endwin()
                edit_snippet_tui(snippets[selected]['id'])
                stdscr = curses.initscr()
                curses.curs_set(0)
                stdscr.keypad(True)
            elif key == ord('d') and snippets:
                curses.endwin()
                delete_snippet_tui(snippets[selected]['id'])
                stdscr = curses.initscr()
                curses.curs_set(0)
                stdscr.keypad(True)
                selected = max(0, selected - 1)
            elif key == ord('y') and snippets:
                copy_to_clipboard(snippets[selected]['content'])
                stdscr.attron(curses.color_pair(2))
                stdscr.addstr(height - 1, 2, "✓ Copied to clipboard!")
                stdscr.attroff(curses.color_pair(2))
                stdscr.refresh()
                curses.napms(1000)
            elif key == ord('/'):
                curses.echo()
                curses.curs_set(1)
                stdscr.addstr(2, 2, "Search: " + " " * (width - 12))
                stdscr.addstr(2, 10, "")
                search_term = stdscr.getstr(2, 10, width - 12).decode('utf-8')
                curses.noecho()
                curses.curs_set(0)
                selected = 0
            elif key == 10 and snippets:  # Enter
                curses.endwin()
                view_snippet_tui(snippets[selected]['id'])
                stdscr = curses.initscr()
                curses.curs_set(0)
                stdscr.keypad(True)
    
    curses.wrapper(main)

def add_snippet_tui():
    """Add snippet via terminal prompts"""
    print("\n╔═══════════════════════════════════╗")
    print("║     Add New Snippet               ║")
    print("╚═══════════════════════════════════╝\n")
    
    title = input("Title: ").strip()
    if not title:
        print("✗ Title cannot be empty")
        input("Press Enter to continue...")
        return
    
    language = input("Language (optional): ").strip()
    tags = input("Tags (comma-separated, optional): ").strip()
    
    print("\nContent (Ctrl+D when done):")
    print("─" * 40)
    
    lines = []
    try:
        while True:
            line = input()
            lines.append(line)
    except EOFError:
        pass
    
    content = "\n".join(lines)
    
    if not content.strip():
        print("\n✗ Content cannot be empty")
        input("Press Enter to continue...")
        return
    
    snippet_id = add_snippet(title, content, language, tags)
    print(f"\n✓ Snippet #{snippet_id} created successfully!")
    input("Press Enter to continue...")

def edit_snippet_tui(snippet_id):
    """Edit snippet in TUI"""
    snippet = get_snippet(snippet_id)
    if not snippet:
        print("✗ Snippet not found")
        input("Press Enter to continue...")
        return
    
    print(f"\n╔═══════════════════════════════════╗")
    print(f"║     Edit Snippet #{snippet_id:<7}           ║")
    print(f"╚═══════════════════════════════════╝\n")
    
    print(f"Current title: {snippet['title']}")
    title = input("New title (or Enter to keep): ").strip()
    if not title:
        title = snippet['title']
    
    print(f"Current language: {snippet['language']}")
    language = input("New language (or Enter to keep): ").strip()
    if not language:
        language = snippet['language']
    
    print(f"Current tags: {snippet['tags']}")
    tags = input("New tags (or Enter to keep): ").strip()
    if not tags:
        tags = snippet['tags']
    
    print("\nCurrent content:")
    print("─" * 40)
    print(snippet['content'][:200])
    print("─" * 40)
    
    edit_content = input("Edit content? (y/N): ").strip().lower()
    if edit_content == 'y':
        print("\nNew content (Ctrl+D when done):")
        print("─" * 40)
        
        lines = []
        try:
            while True:
                line = input()
                lines.append(line)
        except EOFError:
            pass
        
        content = "\n".join(lines)
        if not content.strip():
            content = snippet['content']
    else:
        content = snippet['content']
    
    update_snippet(snippet_id, title, content, language, tags)
    print(f"\n✓ Snippet #{snippet_id} updated successfully!")
    input("Press Enter to continue...")

def delete_snippet_tui(snippet_id):
    """Delete snippet in TUI"""
    snippet = get_snippet(snippet_id)
    if not snippet:
        print("✗ Snippet not found")
        input("Press Enter to continue...")
        return
    
    print(f"\n╔═══════════════════════════════════╗")
    print(f"║     Delete Snippet #{snippet_id:<7}         ║")
    print(f"╚═══════════════════════════════════╝\n")
    
    print(f"Title: {snippet['title']}")
    print(f"Language: {snippet['language']}")
    print(f"Tags: {snippet['tags']}")
    print(f"\nContent preview:")
    print("─" * 40)
    print(snippet['content'][:200])
    print("─" * 40)
    
    confirm = input("\nDelete this snippet? (y/N): ").strip().lower()
    if confirm == 'y':
        delete_snippet(snippet_id)
        print(f"\n✓ Snippet #{snippet_id} deleted!")
    else:
        print("\n✗ Deletion cancelled")
    
    input("Press Enter to continue...")

def view_snippet_tui(snippet_id):
    """View snippet details in TUI"""
    snippet = get_snippet(snippet_id)
    if not snippet:
        print("✗ Snippet not found")
        input("Press Enter to continue...")
        return
    
    print(f"\n╔═══════════════════════════════════╗")
    print(f"║     Snippet #{snippet_id:<7}                 ║")
    print(f"╚═══════════════════════════════════╝\n")
    
    print(f"Title:    {snippet['title']}")
    print(f"Language: {snippet['language']}")
    print(f"Tags:     {snippet['tags']}")
    print(f"Created:  {snippet['created_at']}")
    print(f"Updated:  {snippet['updated_at']}")
    print(f"\nContent:")
    print("─" * 60)
    print(snippet['content'])
    print("─" * 60)
    
    print("\n[y] Copy to clipboard  [Enter] Back")
    action = input("> ").strip().lower()
    
    if action == 'y':
        copy_to_clipboard(snippet['content'])
        print("✓ Copied to clipboard!")
        input("Press Enter to continue...")

def copy_to_clipboard(text):
    """Copy text to clipboard using yank"""
    try:
        proc = subprocess.Popen(['yank'], stdin=subprocess.PIPE)
        proc.communicate(input=text.encode())
        return True
    except FileNotFoundError:
        print("✗ yank not found. Make sure it's installed in BerryCore.")
        return False
    except Exception as e:
        print(f"✗ Error copying to clipboard: {e}")
        return False

# ============================================================================
# CLI Commands
# ============================================================================

def list_snippets():
    """List all snippets in CLI"""
    init_db()
    snippets = get_snippets()
    
    if not snippets:
        print("No snippets found.")
        return
    
    print(f"\n{'ID':<5} {'Title':<30} {'Language':<12} {'Updated':<20}")
    print("─" * 80)
    
    for snippet in snippets:
        snippet_id = str(snippet['id'])
        title = snippet['title'][:28] + ".." if len(snippet['title']) > 30 else snippet['title']
        lang = snippet['language'][:10] if snippet['language'] else ""
        updated = snippet['updated_at'][:19]
        
        print(f"{snippet_id:<5} {title:<30} {lang:<12} {updated:<20}")
    
    print()

def show_help():
    """Show help message"""
    print("""
╔════════════════════════════════════════════════════════════╗
║                  🍇 BerrySnip v1.0                         ║
║         Snippet & Notes Manager for BerryCore              ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  berrysnip web       Start web server (default)
  berrysnip tui       Start TUI interface
  berrysnip add       Quick add snippet (TUI)
  berrysnip list      List all snippets
  berrysnip help      Show this help

WEB INTERFACE:
  Port: 8018
  URL:  http://127.0.0.1:8018
  
  Features:
  - ES5 compliant for BlackBerry browser
  - Add, edit, delete snippets
  - Search and filter by tags
  - Modern responsive UI

TUI INTERFACE:
  Features:
  - Full keyboard navigation
  - Yank clipboard integration (press 'y')
  - Quick search with '/'
  - Add/edit/delete snippets

STORAGE:
  Database: ~/.berrysnip/snippets.db
  SQLite database with full-text search

EXAMPLES:
  # Start web server
  berrysnip web
  
  # Open TUI interface
  berrysnip tui
  
  # List all snippets
  berrysnip list
  
  # Quick add
  berrysnip add

TIPS:
  - Use tags to organize snippets
  - Search works on title, content, and tags
  - Press 'y' in TUI to copy to clipboard via yank
  - Web interface works great on BlackBerry browser

AUTHOR:
  BerryCore Community
  
VERSION:
  1.0.0
""")

# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Main entry point"""
    
    # Handle signals
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    
    if len(sys.argv) < 2:
        command = "web"
    else:
        command = sys.argv[1].lower()
    
    if command == "web":
        start_web_server()
    elif command == "tui":
        tui_interface()
    elif command == "add":
        add_snippet_tui()
    elif command == "list":
        list_snippets()
    elif command == "help" or command == "-h" or command == "--help":
        show_help()
    else:
        print(f"Unknown command: {command}")
        print("Run 'berrysnip help' for usage information.")
        sys.exit(1)

if __name__ == "__main__":
    main()



