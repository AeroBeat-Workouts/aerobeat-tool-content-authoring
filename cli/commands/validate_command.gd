class_name ValidateCommand
extends RefCounted

const ValidatePackageService = preload("../../services/validation/validate_package_service.gd")
const PlainTextOutput = preload("../formatters/plain_text_output.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _validate_package_service: ValidatePackageService = ValidatePackageService.new()
var _plain_text_output: PlainTextOutput = PlainTextOutput.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.is_empty():
		return _result(false, 2, {"error": "validate requires <package_dir>."}, "validate requires <package_dir>.")
	var package_dir: String = String(args[0])
	var report: Dictionary = _validate_package_service.validate_path(package_dir)
	var use_json: bool = args.has("--json")
	return _result(bool(report.get("valid", false)), 0 if report.get("valid", false) else 1, report, _json_output.format_report(report) if use_json else _plain_text_output.format_report(report))

func _result(ok: bool, exit_code: int, data: Dictionary, output: String) -> Dictionary:
	return {
		"ok": ok,
		"exitCode": exit_code,
		"data": data,
		"output": output,
	}
