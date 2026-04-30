class_name PlainTextOutput
extends RefCounted

func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("subject=%s" % [str(report.get("subject", "package"))])
	lines.append("valid=%s" % [str(report.get("valid", false))])
	lines.append("issueCount=%s" % [str(report.get("issueCount", 0))])
	var sections: Dictionary = report.get("sections", {})
	if not sections.is_empty():
		for section_name in sections.keys():
			var section: Dictionary = sections.get(section_name, {})
			lines.append("section.%s.valid=%s" % [str(section_name), str(section.get("valid", false))])
			lines.append("section.%s.issueCount=%s" % [str(section_name), str(section.get("issueCount", 0))])
	for issue_value in report.get("issues", []):
		var issue: Dictionary = issue_value
		lines.append("- [%s] %s (%s)" % [str(issue.get("code", "issue")), str(issue.get("message", "")), str(issue.get("path", ""))])
	return "\n".join(lines)
