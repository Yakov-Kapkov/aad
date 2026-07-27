#!/usr/bin/env bash
set -uo pipefail

FOLDER="${1:-}"
COMMANDS="${2:-test-path,type-path,format-code-path,filter-tool,filter-test-output,validate}"

if [ -z "$FOLDER" ]; then
    echo "error=Usage: read-project-tools.sh <folder> [commands]"
    exit 1
fi

if [ ! -f ".sda/project-tools.md" ]; then
    echo "error=Project not initialized. Run 'setup sda tool' to scaffold project tooling."
    exit 1
fi

export SDA_FOLDER="$FOLDER"
export SDA_COMMANDS="$COMMANDS"

python3 << 'PYEOF'
import sys, os, re

folder     = os.environ['SDA_FOLDER']
commands   = [c.strip().lower() for c in os.environ['SDA_COMMANDS'].split(',')]
tools_file = '.sda/project-tools.md'

SKIP_HEADINGS = {'Area Index', 'Validators', 'Output Filter Command', 'Pre-Commit Checks'}
AREA_COMMANDS = {
    'test-path', 'test-path-coverage', 'test-all',
    'type-path', 'type-all',
    'lint-path', 'lint-all',
    'format-code-path',
    'app-run-start', 'app-run-url', 'app-run-healthcheck',
}

def normalize(p):
    p = p.strip().replace('\\', '/')
    if p in ('.', './', ''):
        return ''
    if p.startswith('./'):
        p = p[2:]
    return p.rstrip('/')

def is_prefix(prefix, folder):
    if prefix == '':
        return True
    ps, fs = prefix.split('/'), folder.split('/')
    if len(ps) > len(fs):
        return False
    return all(ps[i] == fs[i] for i in range(len(ps)))

def get_command(lines, label):
    in_block = False
    want_next = False
    for line in lines:
        if line.startswith('```'):
            in_block = not in_block
            want_next = False
            continue
        if not in_block:
            continue
        if re.match(r'^#\s+' + re.escape(label) + r'(\s|$)', line):
            want_next = True
            continue
        if want_next:
            stripped = line.strip()
            if stripped == '':
                continue
            if stripped.startswith('#'):
                want_next = False
                continue
            return stripped
    return None

with open(tools_file, encoding='utf-8') as f:
    all_lines = f.read().splitlines()

# Parse area blocks
areas = []
cur_area = None
for line in all_lines:
    m = re.match(r'^## (.+)$', line)
    if m:
        heading = m.group(1).strip()
        if cur_area:
            areas.append(cur_area)
        if heading in SKIP_HEADINGS:
            cur_area = None
            continue
        cur_area = {'name': heading, 'workdir': '', 'lines': []}
        continue
    if cur_area is not None:
        cur_area['lines'].append(line)
        m2 = re.match(r'^\*\*Working directory:\*\*\s+`(.+)`', line)
        if m2:
            cur_area['workdir'] = normalize(m2.group(1))
if cur_area:
    areas.append(cur_area)

if not areas:
    print("error=No area blocks found in project-tools.md. Re-run sda-toolscan.")
    sys.exit(1)

# Find best-matching area (longest prefix match)
norm_folder = normalize(folder)
best_area = None
best_len  = -1
for area in areas:
    if is_prefix(area['workdir'], norm_folder):
        length = len(area['workdir'])
        if length > best_len:
            best_len = length
            best_area = area

# Fallback: root area
if best_area is None:
    for area in areas:
        if area['workdir'] == '':
            best_area = area
            break

if best_area is None:
    print(f"error=No area matches folder '{folder}'. Check Working directory entries in project-tools.md.")
    sys.exit(1)

out = []
wd = './' if best_area['workdir'] == '' else best_area['workdir'] + '/'
out.append(f"working-dir={wd}")

area_lines = best_area['lines']

# Area-scoped commands — label name = command name
for cmd in commands:
    if cmd in AREA_COMMANDS:
        v = get_command(area_lines, cmd)
        if v:
            out.append(f"{cmd}={v}")

# Global: shell
if 'shell' in commands:
    for line in all_lines:
        m = re.match(r'^\*\*Detected shell:\*\*\s+(.+)$', line)
        if m:
            out.append(f"shell={m.group(1).strip()}")
            break

# Global: filter-tool
if 'filter-tool' in commands:
    v = get_command(all_lines, 'filter-last-n')
    if v:
        out.append(f"filter-tool={v}")

# Global: filter-test-output
if 'filter-test-output' in commands:
    v = get_command(all_lines, 'filter-test-output')
    if v:
        out.append(f"filter-test-output={v}")

# Global: validate-*-path labels
if 'validate' in commands:
    for lbl in ('validate-json-path', 'validate-yaml-path', 'validate-xml-path', 'validate-toml-path'):
        v = get_command(all_lines, lbl)
        if v:
            out.append(f"{lbl}={v}")

# Global: pre-commit commands
for lbl in ('precommit-all', 'precommit-staged'):
    if lbl in commands:
        v = get_command(all_lines, lbl)
        if v:
            out.append(f"{lbl}={v}")

# Global: areas (Area Index listing — all area names and working directories)
if 'areas' in commands:
    for area in areas:
        wd = './' if area['workdir'] == '' else area['workdir'] + '/'
        out.append(f"area.{area['name']}={wd}")

print('\n'.join(out))
PYEOF
