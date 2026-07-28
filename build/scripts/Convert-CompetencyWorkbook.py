#!/usr/bin/env python3
"""
docs/competencies.xlsx  ->  build/scripts/competency-types.csv
                            build/scripts/competencies.csv

Run after any change to the workbook; the CSVs are what the provisioning
script seeds from, and they are the reviewable artefact.

THREE REPAIRS ARE APPLIED HERE, deliberately and visibly, because the source
workbook carries them and silently loading them would put bad data in
SharePoint:

  1. Rows 48 and 56 have the name and description jammed into column B with
     column C empty. Split on the FIRST "; ".
  2. Row 5 contains the literal text "_x0002_", Excel's escape for control
     character 0x02 — a hyphenation artefact from whatever this was pasted
     out of. Replaced with a hyphen.
  3. Nothing else is invented. Row 5's description is ALSO truncated
     mid-word in the source ("...pursues self-developmen"). That is reported,
     not guessed at.
"""
import csv, re, sys, zipfile
import xml.etree.ElementTree as ET

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
SRC = 'docs/competencies.xlsx'

def read_rows(path):
    z = ET.parse if False else None
    zf = zipfile.ZipFile(path)
    shared = [''.join(t.text or '' for t in si.iter(NS + 't'))
              for si in ET.fromstring(zf.read('xl/sharedStrings.xml')).iter(NS + 'si')]
    sheet = ET.fromstring(zf.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in sheet.iter(NS + 'row'):
        cells = {}
        for c in row.iter(NS + 'c'):
            col = re.match(r'[A-Z]+', c.get('r')).group(0)
            v, t = c.find(NS + 'v'), c.get('t')
            if t == 'inlineStr':
                val = ''.join(x.text or '' for x in c.iter(NS + 't'))
            elif v is None:
                val = ''
            elif t == 's':
                val = shared[int(v.text)]
            else:
                val = v.text
            cells[col] = (val or '').strip()
        rows.append((int(row.get('r')), cells))
    return rows

def unescape(s):
    # Excel escapes control characters as _xNNNN_. 0x02 here is a hyphenation
    # artefact; anything else we surface rather than guess at.
    return re.sub(r'_x0002_', '-', s)

rows = read_rows(SRC)
body = [(n, c) for n, c in rows[1:] if any(c.get(k) for k in 'ABC')]

records, notes = [], []
for n, c in body:
    ctype, name, desc = c.get('A', ''), c.get('B', ''), c.get('C', '')
    if not desc and '; ' in name:                       # repair 1
        name, desc = name.split('; ', 1)
        notes.append(f'row {n}: split name/description out of column B')
    before = desc
    name, desc = unescape(name), unescape(desc)         # repair 2
    if desc != before:
        notes.append(f'row {n}: replaced _x0002_ with a hyphen')
    if re.search(r'_x[0-9A-Fa-f]{4}_', name + desc):
        notes.append(f'row {n}: UNHANDLED control-char escape remains')
    records.append({'Type': ctype.strip(), 'Name': name.strip(), 'Description': desc.strip()})

seen, types = set(), []
for r in records:
    if r['Type'] and r['Type'] not in seen:
        seen.add(r['Type']); types.append(r['Type'])

with open('build/scripts/competency-types.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, ['TypeName', 'SortOrder'])
    w.writeheader()
    for i, t in enumerate(types, 1):
        w.writerow({'TypeName': t, 'SortOrder': i * 10})

with open('build/scripts/competencies.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, ['Type', 'Name', 'Description'])
    w.writeheader()
    w.writerows(records)

print(f'{len(records)} competencies, {len(types)} types: {", ".join(types)}')
print(f'name max {max(len(r["Name"]) for r in records)} chars, '
      f'description max {max(len(r["Description"]) for r in records)} chars')
for n in notes:
    print('  REPAIR', n)
short = [r for r in records if r['Description'] and len(r['Description'].split()[-1]) > 2
         and not r['Description'].rstrip().endswith(('.', '!', '?'))]
for r in short:
    print(f'  REVIEW  "{r["Name"]}" description does not end in a full stop — '
          f'possibly truncated in the source: ...{r["Description"][-40:]!r}')
blank = [r for r in records if not r['Description']]
for r in blank:
    print(f'  REVIEW  "{r["Name"]}" has no description')
