extends RefCounted

const WorkoutAuthoringService = preload("../services/authoring/workout_authoring_service.gd")

static func run() -> Dictionary:
	var result: Dictionary = WorkoutAuthoringService.new().upsert_record({
		"workoutId": " demo_workout ",
		"title": " Demo Workout ",
		"description": " Short boxing and flow block. ",
		"coachConfigId": " coach_demo ",
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
		and String(record.get("workoutId", "")) == "demo_workout" \
		and String(record.get("workoutName", "")) == "Demo Workout" \
		and String(record.get("description", "")) == "Short boxing and flow block." \
		and String(record.get("coachConfigId", "")) == "coach_demo" \
		and Array(record.get("setOrder", [])).size() == 2 \
		and String(record.get("setOrder", [])[0]) == "set_round_01" \
		and String(record.get("setOrder", [])[1]) == "set_round_02" \
		and not record.has("steps") \
		and not record.has("title")
	return {
		"name": "test_workout_authoring_service",
		"passed": passed,
		"details": {
			"result": result,
			"record": record,
		},
	}
