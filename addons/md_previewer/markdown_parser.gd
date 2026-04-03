@tool
extends RefCounted
class_name MarkdownParser

## Converts Markdown text to Godot BBCode for RichTextLabel rendering.
## Supports: headers, bold, italic, code (inline + block), blockquotes,
##           ordered/unordered lists, horizontal rules, links, images (path).

static func parse(md: String) -> String:
	var lines := md.split("\n")
	var output := ""
	var in_code_block := false
	var code_block_lang := ""
	var code_block_lines: Array[String] = []
	var in_ordered_list := false
	var in_unordered_list := false
	var ordered_index := 0

	for raw_line in lines:
		var line: String = raw_line.rstrip(" \t")

		# --- Code block open/close ---
		if line.begins_with("```"):
			if in_code_block:
				# Close code block
				var code_text := "\n".join(code_block_lines)
				code_text = code_text.replace("[", "[lb]")  # Escape BBCode inside code
				output += "[font_size=13][color=#a8b8c8][bgcolor=#1a1f2e][b] %s [/b][/bgcolor][/color][/font_size]\n" % code_block_lang if code_block_lang else ""
				output += "[font_size=12][color=#cdd6f4][bgcolor=#1a1f2e]%s[/bgcolor][/color][/font_size]\n" % code_text
				in_code_block = false
				code_block_lang = ""
				code_block_lines.clear()
			else:
				# Open code block - close any open lists
				if in_unordered_list:
					output += "[/ul]\n"
					in_unordered_list = false
				if in_ordered_list:
					output += "[/ol]\n"
					in_ordered_list = false
				in_code_block = true
				code_block_lang = line.substr(3).strip_edges()
			continue

		if in_code_block:
			code_block_lines.append(raw_line)
			continue

		# --- Empty line ---
		if line.strip_edges() == "":
			if in_unordered_list:
				output += "[/ul]\n"
				in_unordered_list = false
			if in_ordered_list:
				output += "[/ol]\n"
				in_ordered_list = false
			output += "\n"
			continue

		# --- Horizontal rule ---
		if line == "---" or line == "***" or line == "___" \
			or line == "- - -" or line == "* * *":
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			output += "[color=#4a5568]─────────────────────────────────────────────────[/color]\n"
			continue

		# --- Headers ---
		if line.begins_with("#### "):
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			var text := _inline(line.substr(5))
			output += "[font_size=15][color=#e8c87a][b]%s[/b][/color][/font_size]\n" % text
			continue
		if line.begins_with("### "):
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			var text := _inline(line.substr(4))
			output += "[font_size=17][color=#7aa2f7][b]%s[/b][/color][/font_size]\n" % text
			continue
		if line.begins_with("## "):
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			var text := _inline(line.substr(3))
			output += "[font_size=21][color=#89dceb][b]%s[/b][/color][/font_size]\n" % text
			continue
		if line.begins_with("# "):
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			var text := _inline(line.substr(2))
			output += "[font_size=27][color=#f38ba8][b]%s[/b][/color][/font_size]\n" % text
			continue

		# --- Blockquote ---
		if line.begins_with("> "):
			if in_unordered_list: output += "[/ul]\n"; in_unordered_list = false
			if in_ordered_list:   output += "[/ol]\n"; in_ordered_list = false
			var text := _inline(line.substr(2))
			output += "[color=#4a5568]▎[/color] [color=#a6adc8][i]%s[/i][/color]\n" % text
			continue

		# --- Unordered list ---
		var ul_match := _ul_match(line)
		if ul_match != "":
			if in_ordered_list:
				output += "[/ol]\n"
				in_ordered_list = false
			if not in_unordered_list:
				output += "[ul bullet=•]\n"
				in_unordered_list = true
			output += _inline(ul_match) + "\n"
			continue

		# --- Ordered list ---
		var ol_match := _ol_match(line)
		if ol_match != "":
			if in_unordered_list:
				output += "[/ul]\n"
				in_unordered_list = false
			if not in_ordered_list:
				output += "[ol type=1]\n"
				in_ordered_list = true
				ordered_index = 1
			output += _inline(ol_match) + "\n"
			ordered_index += 1
			continue

		# --- Close any open lists ---
		if in_unordered_list:
			output += "[/ul]\n"
			in_unordered_list = false
		if in_ordered_list:
			output += "[/ol]\n"
			in_ordered_list = false

		# --- Normal paragraph line ---
		output += _inline(line) + "\n"

	# Close any dangling open tags
	if in_unordered_list: output += "[/ul]\n"
	if in_ordered_list:   output += "[/ol]\n"
	if in_code_block:
		var code_text := "\n".join(code_block_lines).replace("[", "[lb]")
		output += "[font_size=12][color=#cdd6f4][bgcolor=#1a1f2e]%s[/bgcolor][/color][/font_size]\n" % code_text

	return output


## Process inline Markdown: bold, italic, code, links
static func _inline(text: String) -> String:
	var result := text

	# Escape any raw BBCode brackets first (except ones we add)
	# We handle [lb] ourselves; just escape user brackets
	result = result.replace("[", "[lb]")

	# Inline code  `code`
	result = _replace_pattern(result, "`([^`]+)`",
		"[font_size=12][color=#a6e3a1][bgcolor=#1e2030] $1 [/bgcolor][/color][/font_size]")

	# Bold+italic ***text***
	result = _replace_pattern(result, r"\*\*\*(.+?)\*\*\*", "[b][i]$1[/i][/b]")
	result = _replace_pattern(result, r"___(.+?)___", "[b][i]$1[/i][/b]")

	# Bold **text** or __text__
	result = _replace_pattern(result, r"\*\*(.+?)\*\*", "[b]$1[/b]")
	result = _replace_pattern(result, r"__(.+?)__", "[b]$1[/b]")

	# Italic *text* or _text_
	result = _replace_pattern(result, r"\*(.+?)\*", "[i]$1[/i]")
	result = _replace_pattern(result, r"(?<!\w)_(.+?)_(?!\w)", "[i]$1[/i]")

	# Strikethrough ~~text~~
	result = _replace_pattern(result, r"~~(.+?)~~", "[s]$1[/s]")

	# Links [text](url)
	result = _replace_pattern(result, r"\[([^\]]+)\]\(([^)]+)\)",
		"[color=#7aa2f7][u]$1[/u][/color]")

	# Images ![alt](path) — just show alt text label
	result = _replace_pattern(result, r"!\[([^\]]*)\]\([^)]+\)",
		"[color=#a6adc8][img placeholder: $1][/color]")

	return result


static func _replace_pattern(text: String, pattern: String, replacement: String) -> String:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return text
	return regex.sub(text, replacement, true)


static func _ul_match(line: String) -> String:
	var regex := RegEx.new()
	regex.compile(r"^[\*\-\+] (.+)$")
	var result := regex.search(line)
	if result:
		return result.get_string(1)
	return ""


static func _ol_match(line: String) -> String:
	var regex := RegEx.new()
	regex.compile(r"^\d+\. (.+)$")
	var result := regex.search(line)
	if result:
		return result.get_string(1)
	return ""
