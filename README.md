# AeroBeat Tool Template

This is the official template for creating a **Tool** repository within the AeroBeat ecosystem.

A **Tool** is a reusable service or singleton manager (e.g., API Client, Analytics, Discord Integration). It is designed to be modular and plugged into an **Assembly**.

## 📋 Repository Details

*   **Type:** Tool (Service/Module)
*   **License:** **MPL 2.0** (Weak Copyleft / Library)
*   **Dependencies:**
    *   `aerobeat-core` (Required)
    *   `aerobeat-vendor-*` (Allowed)

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package/published boundary for downstream consumers. Day-to-day development, debugging, and validation happen from the hidden `.testbed/` workbench using the pinned OpenClaw toolchain: Godot `4.6.2 stable standard`.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

That installs the pinned `aerobeat-core` foundation plus GUT into `.testbed/addons/`.

### Open the workbench

From the repo root:

```bash
godot --editor --path .testbed
```

Use this `.testbed/` project as the canonical direct-development and bugfinding surface for tool work.

### Import smoke check

From the repo root:

```bash
godot --headless --path .testbed --import
```

### Run unit tests

From the repo root:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

### Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- The manifest pins `aerobeat-core` to `v0.1.0` and GUT to `main`.
- Repo-local unit tests live under `.testbed/tests/`; the hidden workbench uses the committed `.testbed/src -> ../src` bridge for this repo's `src/`-rooted package layout.
- The current package shape is consumed from the repo root (`subfolder: "/"`) for downstream installs.
