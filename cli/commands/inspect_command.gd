class_name InspectCommand
extends RefCounted

const RefreshContentIndexService = preload("../../services/registry/refresh_content_index_service.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _refresh_content_index_service: RefreshContentIndexService = RefreshContentIndexService.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.size() < 2:
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "inspect requires <manifest|index> <path>."},
			"output": "inspect requires <manifest|index> <path>.",
		}
	var inspect_kind: String = String(args[0])
	var path: String = String(args[1])
	var result: Dictionary
	match inspect_kind:
		"manifest":
			result = {"ok": FileAccess.file_exists(path), "path": path, "manifest": _load_json(path)}
		"index":
			result = _refresh_content_index_service.refresh_index(path)
		_:
			result = {"ok": false, "error": "Unknown inspect kind '%s'." % inspect_kind}
	return {
		"ok": bool(result.get("ok", false)),
		"exitCode": 0 if result.get("ok", false) else 1,
		"data": result,
		"output": _json_output.format_report(result),
	}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed
