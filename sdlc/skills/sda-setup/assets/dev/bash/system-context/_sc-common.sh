#!/usr/bin/env bash
# Shared surgical-edit helpers for the SDA system-context CLI scripts (bash side).
# Mirrors _sc-common.ps1 and emits the identical canonical YAML shape.
# No external tools beyond bash + awk (POSIX). Every write goes through these
# primitives. On failure a script prints  error=<message>  and exits 1.

set -uo pipefail

sc_error() { printf 'error=%s\n' "$1"; exit 1; }
sc_today() { date +%Y-%m-%d; }

sc_is_text_field() {
  case "$1" in claim|summary|rationale|note|path) return 0 ;; *) return 1 ;; esac
}

# sc_format_value FIELD VALUE  -> formatted scalar token
sc_format_value() {
  local field="$1" value="$2"
  if [ -z "$value" ] || [ "$value" = "null" ]; then printf 'null'; return; fi
  if sc_is_text_field "$field"; then
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '"%s"' "$value"
  else
    printf '%s' "$value"
  fi
}

# sc_format_list "a,b"  -> [a, b]   (empty -> [])
sc_format_list() {
  local raw="${1:-}" out="" tok
  raw="${raw//,/ }"
  for tok in $raw; do
    [ -z "$tok" ] && continue
    if [ -z "$out" ]; then out="$tok"; else out="$out, $tok"; fi
  done
  printf '[%s]' "$out"
}

# sc_init_list_file FILE KEY1 [KEY2 ...]
sc_init_list_file() {
  local file="$1"; shift
  [ -f "$file" ] && return 0
  mkdir -p "$(dirname "$file")"
  : > "$file"
  local k
  for k in "$@"; do printf '%s: []\n' "$k" >> "$file"; done
}

# --- awk model ------------------------------------------------------------
# A section = a column-0 "KEY:" line; its items run until the next column-0
# line. An item begins with "  - " and continues on 4-space lines. "KEY: []"
# is an empty section.

# sc_item_exists FILE KEY IDFIELD IDVALUE  -> exit 0 if present
sc_item_exists() {
  awk -v key="$2" -v idf="$3" -v idv="$4" '
    BEGIN{ins=0;found=0}
    $0 ~ "^"key":[ \t]*$" {ins=1;next}
    $0 ~ "^"key":[ \t]*\\[\\][ \t]*$" {ins=0;next}
    /^[^ \t]/ {ins=0}
    ins && $0 ~ "^  - "idf":[ \t]*" {
      v=$0; sub("^  - "idf":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
      if (v==idv || v=="\""idv"\"") {found=1}
    }
    END{exit(found?0:1)}
  ' "$1"
}

# sc_get_field FILE KEY IDFIELD IDVALUE FIELD  -> prints decoded value
sc_get_field() {
  awk -v key="$2" -v idf="$3" -v idv="$4" -v fld="$5" '
    function decode(v){
      gsub(/^[ \t]+|[ \t]+$/,"",v)
      if(v=="null"||v==""){return ""}
      if(substr(v,1,1)=="\"" && substr(v,length(v),1)=="\""){
        v=substr(v,2,length(v)-2); gsub(/\\"/,"\"",v); gsub(/\\\\/,"\\",v)
      }
      return v
    }
    BEGIN{ins=0;initem=0}
    $0 ~ "^"key":[ \t]*$" {ins=1;next}
    $0 ~ "^"key":[ \t]*\\[\\][ \t]*$" {ins=0;next}
    /^[^ \t]/ {ins=0;initem=0}
    ins && /^  - / {
      v=$0; sub("^  - "idf":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
      initem=(v==idv || v=="\""idv"\"")?1:0
      if(initem && idf==fld){print decode(v);exit}
    }
    ins && initem && $0 ~ "^    "fld":[ \t]*" {
      v=$0; sub("^    "fld":[ \t]*","",v); print decode(v); exit
    }
  ' "$1"
}

# sc_get_field_raw FILE KEY IDFIELD IDVALUE FIELD  -> prints raw stored token
sc_get_field_raw() {
  awk -v key="$2" -v idf="$3" -v idv="$4" -v fld="$5" '
    BEGIN{ins=0;initem=0}
    $0 ~ "^"key":[ \t]*$" {ins=1;next}
    $0 ~ "^"key":[ \t]*\\[\\][ \t]*$" {ins=0;next}
    /^[^ \t]/ {ins=0;initem=0}
    ins && /^  - / {
      v=$0; sub("^  - "idf":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
      initem=(v==idv || v=="\""idv"\"")?1:0
    }
    ins && initem && $0 ~ "^    "fld":[ \t]*" {
      v=$0; sub("^    "fld":[ \t]*","",v); gsub(/[ \t]+$/,"",v); print v; exit
    }
  ' "$1"
}

# sc_list_ids FILE KEY [IDFIELD]  -> prints each item's id, one per line
sc_list_ids() {
  awk -v key="$2" -v idf="${3:-id}" '
    function decode(v){gsub(/^[ \t]+|[ \t]+$/,"",v); if(substr(v,1,1)=="\""){v=substr(v,2,length(v)-2)} return v}
    BEGIN{ins=0}
    $0 ~ "^"key":[ \t]*$" {ins=1;next}
    $0 ~ "^"key":[ \t]*\\[\\][ \t]*$" {ins=0;next}
    /^[^ \t]/ {ins=0}
    ins && $0 ~ "^  - "idf":[ \t]*" {v=$0; sub("^  - "idf":[ \t]*","",v); print decode(v)}
  ' "$1"
}

# sc_add_item FILE KEY BLOCKFILE   (BLOCKFILE holds the canonical item lines)
sc_add_item() {
  local file="$1" key="$2" blockfile="$3" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v blockfile="$blockfile" '
    function emit_block(   l){ while((getline l < blockfile)>0) print l; close(blockfile) }
    { lines[NR]=$0 } END{
      keyline=0; inline=0
      for(i=1;i<=NR;i++){
        if(lines[i] ~ "^"key":[ \t]*\\[\\][ \t]*$"){keyline=i;inline=1;break}
        if(lines[i] ~ "^"key":[ \t]*$"){keyline=i;inline=0;break}
      }
      if(keyline==0){ for(i=1;i<=NR;i++)print lines[i]; exit }
      if(inline){
        for(i=1;i<=NR;i++){ if(i==keyline){print key":"; emit_block()} else print lines[i] }
      } else {
        # find section end: next col-0 line after keyline, else NR+1
        endl=NR+1
        for(i=keyline+1;i<=NR;i++){ if(lines[i] ~ /^[^ \t]/){endl=i;break} }
        for(i=1;i<=NR;i++){ if(i==endl){emit_block()} print lines[i] }
        if(endl==NR+1) emit_block()
      }
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# sc_remove_item FILE KEY IDFIELD IDVALUE
sc_remove_item() {
  local file="$1" key="$2" idf="$3" idv="$4" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v idf="$idf" -v idv="$idv" '
    { lines[NR]=$0 } END{
      keyline=0
      for(i=1;i<=NR;i++){ if(lines[i] ~ "^"key":[ \t]*$"){keyline=i;break} }
      if(keyline==0){ for(i=1;i<=NR;i++)print lines[i]; exit }
      endl=NR+1
      for(i=keyline+1;i<=NR;i++){ if(lines[i] ~ /^[^ \t]/){endl=i;break} }
      # locate item block
      istart=0;iend=0;cur=0
      for(i=keyline+1;i<endl;i++){
        if(lines[i] ~ "^  - "){
          if(cur>0){ if(match_id(cur,i)){istart=cur;iend=i;break} }
          cur=i
        }
      }
      if(istart==0 && cur>0){ if(match_id(cur,endl)){istart=cur;iend=endl} }
      # count remaining items
      remaining=0
      for(i=keyline+1;i<endl;i++){ if(lines[i] ~ "^  - "){ if(!(istart>0 && i>=istart && i<iend)) remaining++ } }
      for(i=1;i<=NR;i++){
        if(istart>0 && i>=istart && i<iend) continue
        if(i==keyline && istart>0 && remaining==0){ print key": []"; continue }
        print lines[i]
      }
    }
    function match_id(s,e,   j,v){
      for(j=s;j<e;j++){
        if(lines[j] ~ "^  - "idf":[ \t]*" || lines[j] ~ "^    "idf":[ \t]*"){
          v=lines[j]; sub("^  - "idf":[ \t]*","",v); sub("^    "idf":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
          return (v==idv || v=="\""idv"\"")
        }
      }
      return 0
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# sc_set_field FILE KEY IDFIELD IDVALUE FIELD FORMATTED
sc_set_field() {
  local file="$1" key="$2" idf="$3" idv="$4" fld="$5" val="$6" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v idf="$idf" -v idv="$idv" -v fld="$fld" -v val="$val" '
    { lines[NR]=$0 } END{
      keyline=0
      for(i=1;i<=NR;i++){ if(lines[i] ~ "^"key":[ \t]*$"){keyline=i;break} }
      endl=NR+1
      for(i=keyline+1;i<=NR;i++){ if(lines[i] ~ /^[^ \t]/){endl=i;break} }
      istart=0;iend=0;cur=0
      for(i=keyline+1;i<endl;i++){
        if(lines[i] ~ "^  - "){
          if(cur>0){ if(match_id(cur,i)){istart=cur;iend=i;break} }
          cur=i
        }
      }
      if(istart==0 && cur>0){ if(match_id(cur,endl)){istart=cur;iend=endl} }
      done=0
      for(i=1;i<=NR;i++){
        if(istart>0 && i>=istart && i<iend && !done){
          if(lines[i] ~ "^  - "fld":[ \t]*"){ print "  - "fld": "val; done=1; continue }
          if(lines[i] ~ "^    "fld":[ \t]*"){ print "    "fld": "val; done=1; continue }
        }
        print lines[i]
        if(istart>0 && i==iend-1 && !done){ print "    "fld": "val; done=1 }
      }
    }
    function match_id(s,e,   j,v){
      for(j=s;j<e;j++){
        if(lines[j] ~ "^  - "idf":[ \t]*" || lines[j] ~ "^    "idf":[ \t]*"){
          v=lines[j]; sub("^  - "idf":[ \t]*","",v); sub("^    "idf":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
          return (v==idv || v=="\""idv"\"")
        }
      }
      return 0
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# sc_set_scalar FILE KEY VALUE   (top-level "KEY: VALUE")
sc_set_scalar() {
  local file="$1" key="$2" val="$3" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v val="$val" '
    { if($0 ~ "^"key":[ \t]"){ print key": "val; done=1 } else print }
    END{ if(!done) print key": "val }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}
