#!/usr/bin/env bash
set -u
MAX_ATTEMPTS=3
ATTEMPT=0
SUCCESS=0

run_apply() {
  terraform apply -auto-approve tfplan 2>&1
}

extract_and_import() {
  local output="$1"
  echo "$output" | grep -Po 'A resource with the ID `"[^`"]+`"[^,]+with .*,' | while read -r line; do
    AZ_ID=$(echo "$line" | grep -Po 'ID `"\K[^`"]+')
    TF_RES=$(echo "$line" | sed -E 's/.*with (.*),$/\1/')
    echo "Importing $TF_RES -> $AZ_ID"
    terraform import "$TF_RES" "$AZ_ID"
  done
}

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT+1))
  echo "Attempt #$ATTEMPT"

  OUT=$(run_apply)
  EXIT=$?

  echo "$OUT"

  if [ $EXIT -eq 0 ]; then
    echo "Apply succeeded"
    SUCCESS=1
    break
  fi

  if echo "$OUT" | grep -q 'A resource with the ID'; then
    extract_and_import "$OUT"
  else
    echo "Apply failed with unexpected error"
    break
  fi
done

if [ $SUCCESS -ne 1 ]; then
  echo "Terraform apply failed after $MAX_ATTEMPTS attempts"
  exit 1
fi
