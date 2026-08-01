#!/usr/bin/env python3
"""
docs/program options.xlsx  ->  build/scripts/program-options.csv

Sits next to the provisioning scripts on purpose: they get copied out of WSL to
a Windows path to run, and anything they need has to travel in the same copy.

Reports anything that looks damaged rather than silently loading it — see the
competencies workbook, where two rows had the name and description jammed into
one cell and one description was truncated mid-word.
"""
import csv, re, zipfile
import xml.etree.ElementTree as ET

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
SRC = 'docs/program options.xlsx'
DST = 'build/scripts/program-options.csv'

# Workbook heading -> PROGRAM_OPTIONS column
COLUMNS = [
    ('Program',              'Program'),
    ('Course / Program Name','OptionName'),
    ('Description',          'Description'),
    ('Vendor',               'Vendor'),
    ('Grade Level',          'GradeLevel'),
    ('Course Length',        'CourseLength'),
    ('Competency',           'Competency'),
    ('Requirements',         'Requirements'),
    ('Website',              'Website'),
]

zf = zipfile.ZipFile(SRC)
shared = ([''.join(t.text or '' for t in si.iter(NS + 't'))
           for si in ET.fromstring(zf.read('xl/sharedStrings.xml')).iter(NS + 'si')]
          if 'xl/sharedStrings.xml' in zf.namelist() else [])
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
    rows.append(cells)

header, body = rows[0], [r for r in rows[1:] if any(r.values())]

# Map spreadsheet letters by matching the heading text, not by position — a
# reordered or inserted column would otherwise load silently into the wrong
# field, which is the kind of error nobody notices until it is in production.
letter_for = {}
for letter, text in header.items():
    for heading, field in COLUMNS:
        if text.strip().lower() == heading.lower():
            letter_for[field] = letter
missing = [f for _, f in COLUMNS if f not in letter_for]
if missing:
    raise SystemExit(f'Headings not found in the workbook: {missing}\nSaw: {list(header.values())}')

records = []
for r in body:
    rec = {field: re.sub(r'_x[0-9A-Fa-f]{4}_', '-', r.get(letter_for[field], '')).strip()
           for _, field in COLUMNS}
    records.append(rec)

with open(DST, 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, [f for _, f in COLUMNS])
    w.writeheader()
    w.writerows(records)

print(f'{len(records)} options -> {DST}')
by_program = {}
for r in records:
    by_program.setdefault(r['Program'], 0)
    by_program[r['Program']] += 1
print('by program:', by_program)
print('longest OptionName:', max(len(r['OptionName']) for r in records), 'chars')
print('longest Description:', max(len(r['Description']) for r in records), 'chars')

for i, r in enumerate(records, 2):
    for _, field in COLUMNS:
        if field in ('Program', 'OptionName') and not r[field]:
            print(f'  REVIEW  row {i}: {field} is empty')
    if len(r['OptionName']) > 255:
        print(f'  REVIEW  row {i}: OptionName exceeds 255 chars — Text column limit')
    if re.search(r'_x[0-9A-Fa-f]{4}_', ''.join(r.values())):
        print(f'  REVIEW  row {i}: unhandled control-character escape remains')
