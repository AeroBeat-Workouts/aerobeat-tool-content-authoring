class_name PackageCommand
extends RefCounted

const BuildContentPackageService = preload("../../services/packaging/build_content_package_service.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _build_content_package_service: BuildContentPackageService = BuildContentPackageService.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.size() < 3 or args[1] != "--output":
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "package requires <source_dir> --output <dir>."},
			"output": "package requires <source_dir> --output <dir>.",
		}
	var result: Dictionary = _build_content_package_service.build_package(String(args[0]), String(args[2]))
	return {
		"ok": bool(result.get("ok", false)),
		"exitCode": 0 if result.get("ok", false) else 1,
		"data": result,
		"output": _json_output.format_report(result),
	}
