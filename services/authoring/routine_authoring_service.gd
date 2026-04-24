class_name RoutineAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.content.routine.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var routine := {
		"schema": String(record_data.get("schema", DEFAULT_SCHEMA)),
		"routineId": String(record_data.get("routineId", "")),
		"songId": String(record_data.get("songId", "")),
		"mode": String(record_data.get("mode", "boxing")),
		"title": String(record_data.get("title", "")),
		"charts": record_data.get("charts", []).duplicate(true),
	}
	return {
		"ok": not routine["routineId"].is_empty(),
		"recordKind": "routine",
		"record": routine,
	}
