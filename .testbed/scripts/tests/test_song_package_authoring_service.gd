extends RefCounted

const ADDON_SONG_PACKAGE_AUTHORING_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/authoring/song_package_authoring_service.gd"

static func run() -> Dictionary:
	var result: Dictionary = load(ADDON_SONG_PACKAGE_AUTHORING_SERVICE_PATH).new().upsert_record({
		"songPackageId": " ab-song-package-demo ",
		"title": " Demo Song Package ",
		"description": " Short boxing and flow block. ",
		"packageVersion": " 2.1.0 ",
		"sets": [
			{"setId": " set_round_01 "},
			" set_round_02 ",
		],
		"steps": [
			{"stepId": "legacy_step_01"},
		],
	})
	var record: Dictionary = result.get("record", {})
	var passed := bool(result.get("ok", false)) \
		and String(record.get("songPackageId", "")) == "ab-song-package-demo" \
		and String(record.get("songPackageName", "")) == "Demo Song Package" \
		and String(record.get("description", "")) == "Short boxing and flow block." \
		and String(record.get("packageVersion", "")) == "2.1.0" \
		and Array(record.get("setIds", [])).size() == 2 \
		and String(record.get("setIds", [])[0]) == "set_round_01" \
		and String(record.get("setIds", [])[1]) == "set_round_02" \
		and not record.has("steps") \
		and not record.has("title")
	return {
		"name": "test_song_package_authoring_service",
		"passed": passed,
		"details": {
			"result": result,
			"record": record,
		},
	}
