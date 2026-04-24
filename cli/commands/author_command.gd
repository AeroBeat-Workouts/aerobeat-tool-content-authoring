class_name AuthorCommand
extends RefCounted

const ChartAuthoringService = preload("../../services/authoring/chart_authoring_service.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _chart_authoring_service: ChartAuthoringService = ChartAuthoringService.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.size() < 3:
		return _usage_error("author requires chart upsert <package_dir> --from <chart_json>." )
	var record_kind: String = String(args[0])
	var operation: String = String(args[1])
	if record_kind != "chart" or operation != "upsert":
		return _usage_error("author currently supports only: chart upsert <package_dir> --from <chart_json>.")

	var package_dir: String = String(args[2])
	var chart_json_path := ""
	var use_json := false
	var index := 3
	while index < args.size():
		var token: String = String(args[index])
		match token:
			"--from":
				if index + 1 >= args.size():
					return _usage_error("author chart upsert requires --from <chart_json>.")
				chart_json_path = String(args[index + 1])
				index += 2
			"--json":
				use_json = true
				index += 1
			_:
				return _usage_error("Unknown author option '%s'." % token)

	if chart_json_path.is_empty():
		return _usage_error("author chart upsert requires --from <chart_json>.")

	var chart_data: Dictionary = _load_json(chart_json_path)
	if chart_data.is_empty():
		return {
			"ok": false,
			"exitCode": 1,
			"data": {"error": "Chart input JSON is missing or invalid.", "path": chart_json_path},
			"output": "Chart input JSON is missing or invalid.",
		}

	chart_data["packageDir"] = package_dir
	var result: Dictionary = _chart_authoring_service.upsert_record(chart_data)
	var output: String = _json_output.format_report(result) if use_json else _plain_text_output(result)
	return {
		"ok": bool(result.get("ok", false)),
		"exitCode": 0 if result.get("ok", false) else 1,
		"data": result,
		"output": output,
	}

func _usage_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"exitCode": 2,
		"data": {"error": message},
		"output": message,
	}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _plain_text_output(result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("ok=%s" % String(result.get("ok", false)))
	lines.append("chartPath=%s" % String(result.get("chartPath", "")))
	lines.append("issueCount=%s" % String(result.get("issueCount", 0)))
	if result.has("error"):
		lines.append("error=%s" % String(result.get("error", "")))
	return "\n".join(lines)
