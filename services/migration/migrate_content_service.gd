class_name MigrateContentService
extends RefCounted

func migrate_path(package_dir: String, target_schema: String) -> Dictionary:
	return {
		"ok": true,
		"packageDir": package_dir,
		"targetSchema": target_schema,
		"migrated": false,
		"message": "Migration scaffold is in place; no schema transforms are implemented yet.",
	}
