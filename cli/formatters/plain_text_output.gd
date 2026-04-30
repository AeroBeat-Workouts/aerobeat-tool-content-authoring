class_name PlainTextOutput
extends RefCounted

func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("subject=%s" % [String(report.get("subject", "package"))])
	lines.append("valid=%s" % [String(report.get("valid", false))])
	lines.append("issueCount=%s" % [String(report.get("issueCount", 0))])
	var sections: Dictionary = report.get("sections", {})
	if not sections.is_empty():
		for section_name in sections.keys():
			var section: Dictionary = sections.get(section_name, {})
			lines.append("section.%s.valid=%s" % [String(section_name), String(section.get("valid", false))])
			lines.append("section.%s.issueCount=%s" % [String(section_name), String(section.get("issueCount", 0))])
	for issue in report.get("issues", []):
		lines.append("- [%s] %s (%s)" % [issue.get("code", "issue"), issue.get("message", ""), issue.get("path", "")])
	return "\n".join(lines)
