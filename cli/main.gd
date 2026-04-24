class_name AeroBeatContentAuthoringCli
extends RefCounted

const ValidateCommand = preload("commands/validate_command.gd")
const MigrateCommand = preload("commands/migrate_command.gd")
const PackageCommand = preload("commands/package_command.gd")
const ImportCommand = preload("commands/import_command.gd")
const InspectCommand = preload("commands/inspect_command.gd")
const AuthorCommand = preload("commands/author_command.gd")

var _commands: Dictionary = {
	"validate": ValidateCommand.new(),
	"migrate": MigrateCommand.new(),
	"package": PackageCommand.new(),
	"import": ImportCommand.new(),
	"inspect": InspectCommand.new(),
	"author": AuthorCommand.new(),
}

func run_cli(args: Array) -> Dictionary:
	if args.is_empty():
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "Expected a command."},
			"output": "Expected one of: validate, migrate, package, import, inspect, author.",
		}
	var command_name: String = String(args[0])
	var command: Variant = _commands.get(command_name)
	if command == null:
		return {
			"ok": false,
			"exitCode": 2,
			"data": {"error": "Unknown command '%s'." % command_name},
			"output": "Unknown command '%s'." % command_name,
		}
	return command.execute(args.slice(1))
