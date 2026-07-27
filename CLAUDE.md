## Component library (PowerLibs MCP)

Pre-designed, reusable Power Apps components are available through the PowerLibs
MCP server. They are the default source for UI. Do not hand-author control YAML
for something the library already provides.

### Required order before writing any control YAML

1. `prepare_yaml_generation` — mandatory briefing before generating YAML from scratch
2. `list_components` or `search_components` — find a component that fits
3. `get_component_details` — confirm settings and fit
4. `generate_yaml` with `yaml_mode: "classic"`

### Rules

- `yaml_mode` is always `classic`, never `modern`. Classic controls only
  (constitution, Principle II).
- If no component fits, say so explicitly and state what is missing before
  proposing a custom control. Do not silently build one.
- Rename generated controls to project convention before presenting YAML
  (three-character type prefix, camel case, unique across the app). Library
  names are not compliant.
- Set brand color once via `global_settings.primaryColor` rather than editing
  colors component by component.
- If a paste into Power Apps Studio fails, check `get_yaml_error_patterns`
  (category `power-apps-error`) before rewriting by hand.
- Generated YAML is never deployed. Present it for manual transcription
  (constitution, Principle IV).
