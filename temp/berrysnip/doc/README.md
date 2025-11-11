# BerrySnip - Snippet & Notes Manager for BerryCore

**Version:** 1.0.0  
**Category:** util  
**Author:** BerryCore Community

## Overview

BerrySnip is a dual-interface snippet and notes manager designed specifically for BlackBerry 10 and BerryCore. It provides both a web interface (ES5 compliant for BlackBerry browser) and a terminal TUI interface with yank clipboard integration.

## Features

### Web Interface (Port 8018)
- **ES5 Compliant**: Works perfectly on BlackBerry 10 browser
- **Dark Theme**: Beautiful gradient purple/blue design
- **Full CRUD**: Create, Read, Update, Delete snippets
- **Search**: Real-time search across titles, content, and tags
- **Tags**: Organize snippets with comma-separated tags
- **Language Support**: Specify programming language for syntax reference
- **Responsive**: Mobile-friendly design for BB10 screen

### TUI Interface (ncurses)
- **Keyboard Navigation**: Arrow keys, vim-like controls
- **Yank Integration**: Press 'y' to copy snippet to clipboard
- **Quick Search**: Press '/' to search snippets
- **Add/Edit/Delete**: Full snippet management from terminal
- **Color Support**: Beautiful colored interface

### Storage
- **SQLite Database**: Fast, reliable local storage
- **Location**: `~/.berrysnip/snippets.db`
- **Indexed**: Optimized queries for fast search
- **Portable**: Single file database, easy to backup

## Installation

### Via qpkg (Recommended)

```bash
# Install BerrySnip
qpkg install berrysnip

# BerrySnip is now available!
berrysnip web
```

### Manual Installation

```bash
# Extract to BerryCore
cd /accounts/1000/shared/misc/berrycore
unzip /path/to/util-berrysnip-1.0.zip

# Make executable
chmod +x bin/berrysnip lib/berrysnip/app.py

# Run
berrysnip web
```

## Usage

### Start Web Server

```bash
berrysnip web
# or just
berrysnip

# Access at: http://127.0.0.1:8018
```

### Start TUI Interface

```bash
berrysnip tui
```

**TUI Keyboard Commands:**
- `↑/↓` - Navigate snippets
- `Enter` - View snippet
- `a` - Add new snippet
- `e` - Edit selected snippet
- `d` - Delete selected snippet
- `y` - Copy snippet to clipboard (via yank)
- `/` - Search snippets
- `q` - Quit

### Quick Add Snippet

```bash
berrysnip add
```

Follow the prompts to add a snippet directly from the terminal.

### List All Snippets

```bash
berrysnip list
```

Shows a table of all snippets with ID, title, language, and update time.

### Help

```bash
berrysnip help
```

## Web Interface Guide

### Adding a Snippet

1. Click "**+ Add Snippet**" button
2. Fill in:
   - **Title**: Name for your snippet
   - **Language**: e.g., python, bash, javascript
   - **Tags**: Comma-separated (e.g., `code, utility, script`)
   - **Content**: The actual snippet or note
3. Click "**Save**"

### Viewing a Snippet

- Click any snippet in the list
- Modal shows full content
- Metadata shows language, tags, update time

### Editing a Snippet

1. View the snippet
2. Click "**✏️ Edit**"
3. Modify fields
4. Click "**Save**"

### Deleting a Snippet

1. View the snippet
2. Click "**🗑️ Delete**"
3. Confirm deletion

### Searching

- Type in search box at top
- Searches: titles, content, tags
- Real-time filtering (2+ characters)

### Tags

- Click "**🏷️ Tags**" to see all available tags
- Use tags to categorize snippets
- Filter by clicking tags (future feature)

## Database Schema

```sql
CREATE TABLE snippets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    language TEXT,
    tags TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Dependencies

### Required
- **Python 3.11+**: Install via `qpkg install python3`
- **SQLite3**: Included with Python

### Optional
- **yank**: For clipboard integration (included in BerryCore)
- **curses**: For TUI (included with Python)

## File Locations

```
$NATIVE_TOOLS/
├── bin/
│   └── berrysnip          # Launcher script
├── lib/
│   └── berrysnip/
│       └── app.py         # Main application
└── doc/
    └── berrysnip/
        └── README.md      # This file

User Data:
~/.berrysnip/
└── snippets.db            # SQLite database
```

## Use Cases

### Code Snippets
Store frequently used code snippets:
- Python functions
- Bash one-liners
- SQL queries
- JavaScript utilities

### Configuration Files
Save config snippets:
- SSH configs
- Git configs
- Shell aliases
- Environment variables

### Notes & Reminders
Quick notes and documentation:
- Server IPs and credentials
- API endpoints and keys
- Command references
- Project notes

### Scripts
Store complete scripts:
- Automation scripts
- Deployment commands
- Backup procedures
- Maintenance tasks

## Tips & Tricks

1. **Use Tags Effectively**
   - `script,automation` - Automation scripts
   - `config,server` - Server configurations
   - `code,python` - Python code snippets
   - `note,reference` - Reference notes

2. **Language Specification**
   - Helps identify snippet type quickly
   - Use common names: python, bash, js, sql, etc.

3. **Descriptive Titles**
   - Use clear, searchable titles
   - Include context: "Deploy script for Apache"
   - Avoid generic names like "script1"

4. **Regular Backups**
   ```bash
   # Backup database
   cp ~/.berrysnip/snippets.db ~/backups/snippets-$(date +%Y%m%d).db
   ```

5. **Export Snippets**
   ```bash
   sqlite3 ~/.berrysnip/snippets.db ".dump" > snippets-export.sql
   ```

## Troubleshooting

### Python Not Found

```bash
# Install Python
qpkg install python3

# Verify installation
python3 --version
```

### Port 8018 Already in Use

```bash
# Find process using port
pidin | grep 8018

# Kill process
kill <PID>

# Or change port in app.py
vim $NATIVE_TOOLS/lib/berrysnip/app.py
# Change: PORT = 8018
```

### Yank Not Working

```bash
# Check if yank is installed
which yank

# It should be in BerryCore
# If not, it's included in the base installation
```

### Database Locked

```bash
# If database is locked, ensure no other instance is running
killall python3

# Restart berrysnip
berrysnip web
```

### TUI Display Issues

```bash
# If TUI looks broken, check terminal size
echo $COLUMNS $LINES

# Resize terminal to at least 80x24
# Or use web interface instead
berrysnip web
```

## API Reference

### REST API Endpoints

**GET /api/snippets**
- Query params: `?search=term` or `?tag=tagname`
- Returns: `{"snippets": [...]}`

**GET /api/snippet/{id}**
- Returns: `{id, title, content, language, tags, created_at, updated_at}`

**POST /api/snippets**
- Body: `{title, content, language, tags}`
- Returns: `{id, success: true}`

**POST /api/snippet/{id}/update**
- Body: `{title, content, language, tags}`
- Returns: `{success: true}`

**POST /api/snippet/{id}/delete**
- Returns: `{success: true}`

**GET /api/tags**
- Returns: `{tags: [...]}`

## Future Enhancements

- [ ] Export snippets to file (markdown, JSON)
- [ ] Import from other snippet managers
- [ ] Syntax highlighting in web interface
- [ ] Multi-user support with authentication
- [ ] Snippet sharing via URL
- [ ] Favorites/starred snippets
- [ ] Categories in addition to tags
- [ ] Snippet history/versions
- [ ] Full-text search with ranking
- [ ] Dark/light theme toggle

## License

Part of BerryCore project.  
Free for personal and commercial use.

## Contributing

Part of the BerryCore ecosystem. Contributions welcome!

---

**BerrySnip** - Keep your snippets handy on your BlackBerry! 🍇



