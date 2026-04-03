# Godot MD Previewer
**Version:** 1.0.0 | **Author:** Sebastian Pavel | **Godot:** 4.4+

A lightweight Markdown previewer addon for **Godot 4.4+** that renders `.md` files directly inside the editor, with multi-tab support and auto-reload.

![Godot 4.4](https://img.shields.io/badge/Godot-4.4%2B-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Pure GDScript](https://img.shields.io/badge/pure-GDScript-orange)

## Features

- 📂 Open any `.md` file from your filesystem via file dialog
- 🗂️ Multiple files open in tabs simultaneously
- 🔄 Auto-reloads if the file changes on disk (every 2 seconds)
- 🔁 Manual reload button
- No external dependencies — pure GDScript, uses `RichTextLabel` + BBCode

## Supported Markdown

| Syntax | Rendered as |
|--------|-------------|
| `# H1` `## H2` `### H3` `#### H4` | Colored, sized headers |
| `**bold**` `__bold__` | Bold |
| `*italic*` `_italic_` | Italic |
| `***bold italic***` | Bold + Italic |
| `~~strikethrough~~` | Strikethrough |
| `` `inline code` `` | Monospaced, highlighted |
| ` ```lang ``` ` | Code block with dark background |
| `> blockquote` | Indented italic with side bar |
| `- item` / `* item` | Bullet list |
| `1. item` | Numbered list |
| `---` | Horizontal rule |
| `[text](url)` | Styled link text |

## Known Limitations

- Tables are not rendered (shown as raw text) — coming in a future update
- Images show as placeholder text
- Links are styled but not clickable in the editor context

## Installation

1. Copy the `addons/md_previewer/` folder into your project's `addons/` directory
2. In Godot: **Project → Project Settings → Plugins** → enable **Markdown Previewer**
3. The **MD Preview** tab appears in the bottom panel

## Usage

| Action | How |
|--------|-----|
| Open a file | Click **📂 Open File** |
| Open another file | Click **📂 Open File** again — opens in a new tab |
| Switch tabs | Click tab headers |
| Close a tab | Click **✕ Close Tab** button |
| Force reload | Click **🔄 Reload** |
| Auto-reload | Happens automatically every 2 seconds if the file changed on disk |

## File Structure

```
addons/md_previewer/
├── plugin.cfg              # Addon metadata
├── plugin.gd               # EditorPlugin entry point
├── md_previewer_panel.gd   # Panel logic (tabs, file loading, auto-reload)
├── md_previewer_panel.tscn # Panel scene
└── markdown_parser.gd      # MD → BBCode converter
```

## License

MIT
