class_name WorkoutAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.content.workout.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var workout_name: String = String(record_data.get("workoutName", record_data.get("title", ""))).strip_edges()
	var workout := {
		"schema": String(record_data.get("schema", DEFAULT_SCHEMA)),
		"workoutId": String(record_data.get("workoutId", "")).strip_edges(),
		"workoutName": workout_name,
		"description": String(record_data.get("description", "")).strip_edges(),
		"coachConfigId": String(record_data.get("coachConfigId", "")).strip_edges(),
		"setOrder": _normalize_set_order(record_data.get("setOrder", record_data.get("sets", []))),
	}
	return {
		"ok": not workout["workoutId"].is_empty(),
		"recordKind": "workout",
		"record": workout,
	}

func _normalize_set_order(value: Variant) -> Array:
	if not (value is Array):
		return []
	var normalized: Array = []
	for entry in value:
		if entry is Dictionary:
			normalized.append(String(entry.get("setId", "")).strip_edges())
		else:
			normalized.append(String(entry).strip_edges())
	return normalized
