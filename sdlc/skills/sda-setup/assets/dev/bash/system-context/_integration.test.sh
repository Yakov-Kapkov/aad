#!/usr/bin/env bash
# End-to-end integration test for the bash system-context CLI scripts.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$(mktemp -d)"
SC="$DIR/sysctx"
mkdir -p "$SC"
fail=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=$((fail+1)); fi; }
run() { bash "$HERE/$1" "${@:2}"; }
readf() { cat "$SC/$1"; }

# domains
o="$(run domains.sh add --name auth --project demo --root "$SC")"
check "domain add ok" '[[ "$o" == *"ok: added domain auth"* ]]'
check "index has auth" 'grep -q "name: auth" "$SC/index.yaml"'
check "domain file created" '[ -f "$SC/auth.yaml" ]'
run domains.sh add --name user --root "$SC" >/dev/null
check "second domain" 'grep -q "name: user" "$SC/index.yaml"'

# components
o="$(run components.sh add --id auth-api --type api --path src/auth/api.ts --domain auth --root "$SC")"
check "component add" '[[ "$o" == *"ok: added component auth-api"* ]]'
run components.sh add --id token-svc --type service --path src/auth/token.ts --domain auth --root "$SC" >/dev/null
run components.sh add --id user-api --type api --path src/user/api.ts --domain user --root "$SC" >/dev/null
check "three components" '[ "$(grep -c "^  - id:" "$SC/dependency-map.yaml")" = "3" ]'
o="$(run components.sh add --id auth-api --type api --path x --domain auth --root "$SC")"
check "dup component rejected" '[[ "$o" == error=* ]]'

# component update
run components.sh update --id auth-api --path src/auth/v2.ts --root "$SC" >/dev/null
check "component update" 'grep -q "path: \"src/auth/v2.ts\"" "$SC/dependency-map.yaml"'

# edges
o="$(run edges.sh add --from auth-api --to token-svc --root "$SC")"
check "edge add" '[[ "$o" == *"ok: added edge auth-api -> token-svc"* ]]'
run edges.sh add --from user-api --to auth-api --root "$SC" >/dev/null
check "edge add 2" 'grep -q "from: user-api" "$SC/dependency-map.yaml"'
o="$(run edges.sh add --from auth-api --to token-svc --root "$SC")"
check "edge dedup" '[[ "$o" == *"already present"* ]]'
o="$(run edges.sh add --from auth-api --to ghost --root "$SC")"
check "edge missing node" '[[ "$o" == error=* ]]'

# decisions
o="$(run decisions.sh add --domain auth --id D001 --summary "JWT: stateless" --rationale scale --root "$SC")"
check "decision add" '[[ "$o" == *"ok: added decision D001"* ]]'
check "decision text quoted" 'grep -q "summary: \"JWT: stateless\"" "$SC/auth.yaml"'
run decisions.sh update --domain auth --id D001 --status superseded --superseded-by D002 --root "$SC" >/dev/null
check "decision supersede" 'grep -q "superseded_by: D002" "$SC/auth.yaml"'

# behaviors (domain)
o="$(run behaviors.sh add --domain auth --id B001 --claim "rejects expired token" --via auth-api --status verified --verified-by TC-1 --root "$SC")"
check "behaviour add" '[[ "$o" == *"ok: added behaviour B001"* ]]'
check "behaviour verified_by" 'grep -q "verified_by: TC-1" "$SC/auth.yaml"'
run behaviors.sh update --domain auth --id B001 --status pending-reverification --note "touched by change" --root "$SC" >/dev/null
check "behaviour update" 'grep -q "status: pending-reverification" "$SC/auth.yaml"'
check "behaviour note" 'grep -q "note: \"touched by change\"" "$SC/auth.yaml"'

# behaviors (cross-domain)
run behaviors.sh add --domain cross-domain --id XB001 --claim "login issues user session" --via "auth-api,user-api" --domains "auth,user" --status verified --root "$SC" >/dev/null
check "cross behaviour file" '[ -f "$SC/cross-domain.yaml" ]'
check "cross via list" 'grep -q "via: \[auth-api, user-api\]" "$SC/cross-domain.yaml"'

# blast-radius
o="$(run blast-radius.sh --components token-svc --root "$SC")"
check "blast at-risk auth-api" '[[ "$o" == *"auth-api"* ]]'
check "blast at-risk user-api" '[[ "$o" == *"user-api"* ]]'
check "blast finds B001" '[[ "$o" == *"behaviour=B001"* ]]'
check "blast pending count" '[[ "$o" == *"pending-count=1"* ]]'

# cascade delete
o="$(run components.sh delete --id auth-api --root "$SC")"
check "delete reports component" '[[ "$o" == *"removed: component auth-api"* ]]'
check "delete cascades B001" '[[ "$o" == *"removed: behaviour B001"* ]]'
check "delete cascades XB001" '[[ "$o" == *"removed: behaviour XB001"* ]]'
check "auth-api gone from map" '! grep -q "id: auth-api" "$SC/dependency-map.yaml"'
check "B001 gone" '! grep -q "id: B001" "$SC/auth.yaml"'
check "edge to auth-api stripped" '! grep -q "to: \[auth-api\]" "$SC/dependency-map.yaml"'

# domain delete
run domains.sh delete --name user --root "$SC" >/dev/null
check "domain delete" '[ ! -f "$SC/user.yaml" ]'
check "domain unregistered" '! grep -q "name: user" "$SC/index.yaml"'

rm -rf "$DIR"
if [ "$fail" = "0" ]; then echo; echo "ALL PASS"; exit 0; else echo; echo "$fail FAILED"; exit 1; fi
