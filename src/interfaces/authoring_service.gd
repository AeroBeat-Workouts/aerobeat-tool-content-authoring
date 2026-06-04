class_name AuthoringService
extends RefCounted

func upsert_record(record_data: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": "AuthoringService.upsert_record must be implemented by a concrete service.",
		"record": record_data,
	}
