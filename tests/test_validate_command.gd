extends RefCounted

const ValidateCommand = preload("../cli/commands/validate_command.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_dir: String = TestSupport.demo_package_dir()
	var full_result: Dictionary = ValidateCommand.new().execute([fixture_dir, "--json"])
	var full_report: Dictionary = full_result.get("data", {})
	var songs_result: Dictionary = ValidateCommand.new().execute(["songs", fixture_dir, "--json"])
	var songs_report: Dictionary = songs_result.get("data", {})
	var passed: bool = bool(full_result.get("ok", false)) \
		and bool(full_report.get("valid", false)) \
		and int(full_report.get("issueCount", -1)) == 0 \
		and full_report.get("sections", {}).has("workout") \
		and bool(songs_result.get("ok", false)) \
		and bool(songs_report.get("valid", false))
	return {
		"name": "test_validate_command",
		"passed": passed,
		"details": {
			"fixtureDir": fixture_dir,
			"fullResult": full_result,
			"songsResult": songs_result,
		},
	}
