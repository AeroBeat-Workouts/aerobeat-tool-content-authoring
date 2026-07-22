extends RefCounted

const ADDON_VALIDATE_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_package_service.gd"
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var base_fixture_dir: String = TestSupport.demo_package_dir()
	var invalid_dir: String = TestSupport.tmp_dir("validate_song_timing_contract_invalid")
	TestSupport.ensure_clean_dir(invalid_dir)
	TestSupport.copy_tree(base_fixture_dir, invalid_dir)
	var song_package_path: String = invalid_dir.path_join("song.package.yaml")
	var song_package_text: String = TestSupport.read_text(song_package_path)
	song_package_text = song_package_text.replace("  timing:\n    anchorMs: 0\n    tempoSegments:", "  timing:\n    anchorMs: 0\n    bpm: 132\n    tempoSegments:")
	TestSupport.write_text(song_package_path, song_package_text)

	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(invalid_dir, "songs")
	var issue_codes := TestSupport.issue_codes(report.get("issues", []))
	var passed: bool = not bool(report.get("valid", true)) and issue_codes.has("song_timing_bpm_shortcut_forbidden")
	return {
		"name": "test_validate_song_timing_contract",
		"passed": passed,
		"details": {
			"fixtureDir": invalid_dir,
			"report": report,
			"issueCodes": issue_codes,
		},
	}
