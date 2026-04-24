class_name PlainTextOutput
extends RefCounted

func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("valid=%s" % [String(report.get("valid", false))])
	lines.append("issueCount=%s" % [String(report.get("issueCount", 0))])
	for issue in report.get("issues", []):
		lines.append("- [%s] %s (%s)" % [issue.get("code", "issue"), issue.get("message", ""), issue.get("path", "")])
	return "
".join(lines)
