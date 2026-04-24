class_name ImportCommand
extends RefCounted

const AudioMetadataImportService = preload("../../services/importers/audio_metadata_import_service.gd")
const ExternalChartImportService = preload("../../services/importers/external_chart_import_service.gd")
const JsonOutput = preload("../formatters/json_output.gd")

var _audio_metadata_import_service: AudioMetadataImportService = AudioMetadataImportService.new()
var _external_chart_import_service: ExternalChartImportService = ExternalChartImportService.new()
var _json_output: JsonOutput = JsonOutput.new()

func execute(args: Array) -> Dictionary:
	if args.size() < 2:
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "import requires <audio-metadata|chart> <source_path>."},
			"output": "import requires <audio-metadata|chart> <source_path>.",
		}
	var import_kind: String = String(args[0])
	var source_path: String = String(args[1])
	var result: Dictionary
	match import_kind:
		"audio-metadata":
			result = _audio_metadata_import_service.import_source(source_path)
		"chart":
			result = _external_chart_import_service.import_source(source_path)
		_:
			result = {"ok": false, "error": "Unknown import kind '%s'." % import_kind}
	return {
		"ok": bool(result.get("ok", false)),
		"exitCode": 0 if result.get("ok", false) else 1,
		"data": result,
		"output": _json_output.format_report(result),
	}
