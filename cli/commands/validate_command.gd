class_name ValidateCommand
extends RefCounted

const ValidatePackageService = preload("../../services/validation/validate_package_service.gd")
const PlainTextOutput = preload("../formatters/plain_text_output.gd")
const JsonOutput = preload("../formatters/json_output.gd")

const VALID_SUBJECTS := ["package", "workout", "songs", "charts", "sets", "coaches", "environments", "assets", "sql"]

var _validate_package_service: ValidatePackageService = ValidatePackageService.new()
var _plain_text_output: PlainTextOutput = PlainTextOutput.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	var use_json: bool = args.has("--json")
	var positionals: Array = []
	for arg in args:
		if String(arg) == "--json":
			continue
		positionals.append(String(arg))
	if positionals.is_empty():
		return _result(false, 2, {"error": "validate requires <package_dir> or <subject> <package_dir>."}, "validate requires <package_dir> or <subject> <package_dir>.")
	var subject := "package"
	var package_dir := ""
	if positionals.size() == 1:
		package_dir = String(positionals[0])
	else:
		subject = String(positionals[0]).to_lower()
		package_dir = String(positionals[1])
	if not VALID_SUBJECTS.has(subject):
		return _result(false, 2, {"error": "Unknown validate subject '%s'." % subject}, "Unknown validate subject '%s'." % subject)
	var report: Dictionary = _validate_package_service.validate_path(package_dir, subject)
	return _result(bool(report.get("valid", false)), 0 if report.get("valid", false) else 1, report, _json_output.format_report(report) if use_json else _plain_text_output.format_report(report))

func _result(ok: bool, exit_code: int, data: Dictionary, output: String) -> Dictionary:
	return {
		"ok": ok,
		"exitCode": exit_code,
		"data": data,
		"output": output,
	}
