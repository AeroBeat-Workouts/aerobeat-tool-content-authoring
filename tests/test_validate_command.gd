extends RefCounted

const ValidateCommand = preload("../cli/commands/validate_command.gd")

static func run() -> Dictionary:
	var fixture_dir: String = _fixture_dir("package_minimal_boxing")
	var result: Dictionary = ValidateCommand.new().execute([fixture_dir, "--json"])
	var report: Dictionary = result.get("data", {})
	var passed := bool(result.get("ok", false)) and bool(report.get("valid", false)) and int(report.get("issueCount", -1)) == 0
	return {
		"name": "test_validate_command",
		"passed": passed,
		"details": {
			"fixtureDir": fixture_dir,
			"result": result,
		},
	}

static func _fixture_dir(name: String) -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/%s" % name)
