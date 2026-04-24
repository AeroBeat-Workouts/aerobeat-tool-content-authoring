class_name JsonOutput
extends RefCounted

func format_report(report: Dictionary) -> String:
	return JSON.stringify(report, "  ")
