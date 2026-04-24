class_name ContentErrorMapper
extends RefCounted

func map_issue(issue: Dictionary) -> Dictionary:
	return {
		"label": "[%s] %s" % [issue.get("code", "issue"), issue.get("message", "")],
		"path": issue.get("path", ""),
		"severity": issue.get("severity", "error"),
		"reference": issue.get("reference", {}),
	}
