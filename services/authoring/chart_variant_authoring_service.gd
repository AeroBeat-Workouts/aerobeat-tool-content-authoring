class_name ChartVariantAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.content.chart_variant.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var chart := {
		"schema": String(record_data.get("schema", DEFAULT_SCHEMA)),
		"chartId": String(record_data.get("chartId", "")),
		"routineId": String(record_data.get("routineId", "")),
		"songId": String(record_data.get("songId", "")),
		"mode": String(record_data.get("mode", "boxing")),
		"difficulty": String(record_data.get("difficulty", "medium")),
		"interactionFamily": String(record_data.get("interactionFamily", "gesture_2d")),
		"events": record_data.get("events", []).duplicate(true),
	}
	return {
		"ok": not chart["chartId"].is_empty(),
		"recordKind": "chart",
		"record": chart,
	}
