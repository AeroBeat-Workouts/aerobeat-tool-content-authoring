class_name ImportExportService
extends RefCounted

func import_source(source_path: String, options: Dictionary = {}) -> Dictionary:
	return {
		"ok": false,
		"error": "ImportExportService.import_source must be implemented by a concrete service.",
		"sourcePath": source_path,
		"options": options,
	}
