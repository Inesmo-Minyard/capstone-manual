#!/usr/bin/env bash
# Stopwatch for the manual deployment procedure (PROCEDURE.md).
# The operator performs every step by hand; this script only records times.
set -euo pipefail

VERSION="${1:?usage: $0 <version>}"
NS=app-manual
DEPLOY=capstone-app
CSV="$HOME/capstone/results/manual-runs.csv"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "$CSV")"
[ -f "$CSV" ] || echo "run_id,method,version,step,start,end,duration_s,status" > "$CSV"

now() { date +%s.%N; }

record() {  # step start end status
  local dur
  dur=$(awk "BEGIN {printf \"%.3f\", $3 - $2}")
  echo "$RUN_ID,manual,$VERSION,$1,$2,$3,$dur,$4" >> "$CSV"
  printf '  %-12s %8.1f s  %s\n' "$1" "$dur" "$4"
}

manual_step() {  # name description
  local start
  start=$(now)
  read -rp "[$1] $2 -> press Enter when done "
  record "$1" "$start" "$(now)" ok
}

wait_ready() {
  local start ip
  start=$(now)
  if ! kubectl rollout status "deployment/$DEPLOY" -n "$NS" --timeout=300s >/dev/null; then
    record wait_ready "$start" "$(now)" failed
    exit 1
  fi
  ip=$(kubectl get svc "$DEPLOY" -n "$NS" -o jsonpath='{.spec.clusterIP}')
  until curl -s -m 1 "http://$ip/" | grep -q "\"version\":\"$VERSION\""; do
    sleep 0.2
  done
  record wait_ready "$start" "$(now)" ok
}

echo "Run $RUN_ID: manual deployment of version $VERSION"
read -rp "Press Enter to START the clock "

manual_step build  "docker build"
manual_step push   "docker push"
manual_step edit   "set image tag in deployment.yaml"
manual_step apply  "kubectl apply"
echo "[wait_ready] waiting for rollout and new version..."
wait_ready
manual_step record "git commit and push in capstone-manual"

echo "Done. Results appended to $CSV"
