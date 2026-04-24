class_name PackageBuildService
extends RefCounted

func build_package(source_dir: String, output_dir: String) -> Dictionary:
	return {
		"ok": false,
		"error": "PackageBuildService.build_package must be implemented by a concrete service.",
		"sourceDir": source_dir,
		"outputDir": output_dir,
	}
