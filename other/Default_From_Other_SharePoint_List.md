# Default a field from another SharePoint list

Pattern for a control whose `Default` is a `LookUp` against a *different*
SharePoint list, editable by the user, and empty when no matching row exists.

```yaml
- txtGrade:
    Control: Classic/TextInput@0.0.54
    Properties:
      Default: |-
        =Coalesce(
           LookUp(EMPLOYEE_DIRECTORY, Email = User().Email).Grade,
           "")
```

## How it works

- `LookUp` returns Blank if no row matches — no error, no crash.
- `Coalesce` returns the first non-blank argument, so a missing row falls
  through to `""`.
- The user can type over it; `Self.Text` on save carries whatever they left
  in the box.

## Two things to know

- `Default` reads once when the control initialises. If the source record
  changes without the control unmounting, call `Reset(txtGrade)` to re-read.
- If the source field is itself a lookup or choice column, adjust the tail:
  `.Grade.Value` for a choice, `.Grade.Value` (display) or `.Grade.Id` (key)
  for a lookup.
