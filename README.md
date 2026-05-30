# Godot MD Editor + Previewer

**Version:** 1.1.0 | **Author:** Sebastian Pavel (feat. binarie) | **Godot:** 4.4+

A lightweight Markdown previewer addon for **Godot 4.4+** that renders `.md` files directly inside the editor, with multi-tab support, auto-reload, image rendering, and the ability to develop your documentation without ever leaving
the editor!

![Godot 4.4](https://img.shields.io/badge/Godot-4.4%2B-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Pure GDScript](https://img.shields.io/badge/pure-GDScript-orange) ![Version](https://img.shields.io/badge/version-1.2.0-purple)

## Features

- 📂 Open any `.md` file from your filesystem via file dialog
- 🗂️ Multiple files open in tabs simultaneously
- 🔄 Auto-reloads if the file changes on disk (every 2 seconds)
- 🖼️ Local and external image rendering (PNG, JPG, WebP, BMP) with auto-retry
- 🔍 Selectable text
- ↪ Clickable links
- ✏️ Ability to update and create new files
- 💾 Saves your open files between sessions!
- No external dependencies, only GDScript, uses `RichTextLabel` + BBCode

## Supported Markdown

| Syntax                            | Rendered as                     |
| --------------------------------- | ------------------------------- |
| `# H1` `## H2` `### H3` `#### H4` | Colored, sized headers          |
| `**bold**` `__bold__`             | Bold                            |
| `*italic*` `_italic_`             | Italic                          |
| `***bold italic***`               | Bold + Italic                   |
| `~~strikethrough~~`               | Strikethrough                   |
| `` `inline code` ``               | Monospaced, highlighted         |
| ` ```lang ``` `                   | Code block with dark background |
| `> blockquote`                    | Indented italic with side bar   |
| `- item` / `* item`               | Bullet list                     |
| `1. item`                         | Numbered list                   |
| `---`                             | Horizontal rule                 |
| `[text](url)`                     | Styled link text                |
| `![alt](path)`                    | Local and external images       |

## Known Limitations

- Tables are not rendered (shown as raw text) — coming in a future update
- GIF images are not supported — Godot 4 has no native GIF decoder

## Installation

1. Copy the `md_previewer/` folder into your project's `addons/` directory
2. In Godot: **Project → Project Settings → Plugins** → enable **Markdown Previewer**
3. The **MD Preview** tab appears in the bottom panel

## Usage

| Action            | How                                                               |
| ----------------- | ----------------------------------------------------------------- |
| Open a file       | Click **📂 Open File**                                            |
| Open another file | Click **📂 Open File** again -> opens in a new tab                |
| Switch tabs       | Click tab headers                                                 |
| Close a tab       | Click **✕ Close Tab** button                                      |
| Create New        | Click **📜 Create New** button                                    |
| Edit a File       | Click **✏️ Edit File** button                                     |
| Save a File       | Click **💾 Save File** button                                     |
| Auto-reload       | Happens automatically every 2 seconds if the file changed on disk |

## File Structure

```
addons/md_previewer/
├── plugin.cfg              # Addon metadata
├── plugin.gd               # EditorPlugin entry point
├── md_previewer_panel.gd   # Panel logic (tabs, file loading, auto-reload, image loading)
├── md_previewer_panel.tscn # Panel scene
└── markdown_parser.gd      # MD → BBCode converter
```

## License

MIT
