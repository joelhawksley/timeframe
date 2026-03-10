#!/usr/bin/env bash
# Integration test: builds and runs the Timeframe Docker container,
# then verifies it starts and responds to HTTP requests.
set -euo pipefail

CONTAINER_NAME="timeframe-integration-test"
IMAGE_NAME="timeframe-test"
PORT=8099
MAX_WAIT=60

cleanup() {
  echo "Cleaning up..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "==> Starting container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT:$PORT" \
  -e RAILS_ENV=production \
  -e SECRET_KEY_BASE=test-secret-key-base-for-integration-test \
  "$IMAGE_NAME"

echo "==> Waiting for server to start (up to ${MAX_WAIT}s)..."
elapsed=0
until curl -sf "http://localhost:$PORT/status" > /dev/null 2>&1; do
  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "FAIL: Server did not start within ${MAX_WAIT}s"
    echo "==> Container logs:"
    docker logs "$CONTAINER_NAME"
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo "Server ready after ~${elapsed}s"

FAILURES=0

# Test 1: Status endpoint returns valid JSON with api health info
echo "==> Test 1: GET /status returns JSON with API health data"
STATUS_RESPONSE=$(curl -sf "http://localhost:$PORT/status")
if echo "$STATUS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
apis = data['apis']
names = [a['name'] for a in apis]
assert 'HomeAssistantApi' in names, 'Missing HomeAssistantApi'
assert 'WeatherKitApi' in names, 'Missing WeatherKitApi'
for a in apis:
    assert 'healthy' in a, f'Missing healthy key in {a[\"name\"]}'
    assert 'last_fetched_at' in a, f'Missing last_fetched_at key in {a[\"name\"]}'
print('PASS')
"; then
  echo "  Test 1 passed"
else
  echo "  FAIL: Test 1"
  FAILURES=$((FAILURES + 1))
fi

# Test 2: Root page includes display links and status table
echo "==> Test 2: GET / returns HTML with display links"
ROOT_RESPONSE=$(curl -sf "http://localhost:$PORT/")
check_content() {
  if echo "$ROOT_RESPONSE" | grep -q "$1"; then
    return 0
  else
    echo "  Missing expected content: $1"
    return 1
  fi
}

ROOT_OK=true
check_content "/mira" || ROOT_OK=false
check_content "/thirteen" || ROOT_OK=false
check_content "Timeframe" || ROOT_OK=false
check_content "API Status" || ROOT_OK=false

if $ROOT_OK; then
  echo "  Test 2 passed"
else
  echo "  FAIL: Test 2"
  FAILURES=$((FAILURES + 1))
fi

# Test 3: Mira display endpoint responds
echo "==> Test 3: GET /mira returns 200"
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$PORT/mira")
if [ "$HTTP_CODE" = "200" ]; then
  echo "  Test 3 passed"
else
  echo "  FAIL: Test 3 (got HTTP $HTTP_CODE)"
  FAILURES=$((FAILURES + 1))
fi

# Test 4: Thirteen display endpoint responds
echo "==> Test 4: GET /thirteen returns 200"
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$PORT/thirteen")
if [ "$HTTP_CODE" = "200" ]; then
  echo "  Test 4 passed"
else
  echo "  FAIL: Test 4 (got HTTP $HTTP_CODE)"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All integration tests passed!"
  exit 0
else
  echo "$FAILURES test(s) failed"
  echo "==> Container logs:"
  docker logs "$CONTAINER_NAME"
  exit 1
fi
