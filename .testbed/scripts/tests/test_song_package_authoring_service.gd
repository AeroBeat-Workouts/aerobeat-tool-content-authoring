extends RefCounted

const ADDON_SONG_PACKAGE_AUTHORING_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/authoring/song_package_authoring_service.gd"

static func run() -> Dictionary:
	var result: Dictionary = load(ADDON_SONG_PACKAGE_AUTHORING_SERVICE_PATH).new().upsert_record({
		"songId": " ab-song-demo ",
		"title": " Demo Song Package ",
		"packageVersion": " 2.1.0 ",
		"charts": [
			{"chartId": " ab-chart-demo-boxing-hard ", "mode": " boxing ", "difficulty": " Hard ", "path": " charts/ab-chart-demo-boxing-hard.yaml "},
		],
	})
	var record: Dictionary = result.get("record", {})
	var charts: Array = Array(record.get("charts", []))
	var first_chart: Dictionary = Dictionary(charts[0]) if not charts.is_empty() else {}
	var passed := bool(result.get("ok", false)) \
		and String(record.get("songId", "")) == "ab-song-demo" \
		and String(record.get("songName", "")) == "Demo Song Package" \
		and String(record.get("packageVersion", "")) == "2.1.0" \
		and charts.size() == 1 \
		and String(first_chart.get("chartId", "")) == "ab-chart-demo-boxing-hard" \
		and String(first_chart.get("mode", "")) == "boxing" \
		and String(first_chart.get("difficulty", "")) == "Hard" \
		and String(first_chart.get("path", "")) == "charts/ab-chart-demo-boxing-hard.yaml" \
		and not record.has("title")
	return {
		"name": "test_song_package_authoring_service",
		"passed": passed,
		"details": {
			"result": result,
			"record": record,
		},
	}
