class_name AudioMetadataImportService
extends "../../interfaces/import_export_service.gd"

func import_source(source_path: String, options: Dictionary = {}) -> Dictionary:
	var file_name: String = source_path.get_file().get_basename()
	return {
		"ok": FileAccess.file_exists(source_path),
		"sourcePath": source_path,
		"recordKind": "song",
		"record": {
			"schema": "aerobeat.content.song.v1",
			"songId": String(options.get("songId", file_name.to_lower().replace(" ", "_"))),
			"title": String(options.get("title", file_name.capitalize())),
			"audioPath": source_path,
		},
	}
