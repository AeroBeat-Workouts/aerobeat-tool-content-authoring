class_name WorkoutAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.content.workout.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var workout := {
		"schema": String(record_data.get("schema", DEFAULT_SCHEMA)),
		"workoutId": String(record_data.get("workoutId", "")),
		"title": String(record_data.get("title", "")),
		"steps": record_data.get("steps", []).duplicate(true),
	}
	return {
		"ok": not workout["workoutId"].is_empty(),
		"recordKind": "workout",
		"record": workout,
	}
