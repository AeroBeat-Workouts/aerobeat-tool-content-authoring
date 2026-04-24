class_name MigrateCommand
extends RefCounted

const MigrateContentService = preload("../../services/migration/migrate_content_service.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _migrate_content_service: MigrateContentService = MigrateContentService.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.size() < 3 or args[1] != "--target-schema":
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "migrate requires <package_dir> --target-schema <schema>."},
			"output": "migrate requires <package_dir> --target-schema <schema>.",
		}
	var result: Dictionary = _migrate_content_service.migrate_path(String(args[0]), String(args[2]))
	return {
		"ok": bool(result.get("ok", false)),
		"exitCode": 0 if result.get("ok", false) else 1,
		"data": result,
		"output": _json_output.format_report(result),
	}
