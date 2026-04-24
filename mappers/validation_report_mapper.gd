class_name ValidationReportMapper
extends RefCounted

const ContentErrorMapper = preload("content_error_mapper.gd")

var _content_error_mapper: ContentErrorMapper = ContentErrorMapper.new()

func to_editor_model(report: Dictionary) -> Dictionary:
	var mapped_issues: Array = []
	for issue in report.get("issues", []):
		mapped_issues.append(_content_error_mapper.map_issue(issue))
	return {
		"valid": report.get("valid", false),
		"issueCount": report.get("issueCount", 0),
		"issues": mapped_issues,
	}
