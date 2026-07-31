# Vowd load testing

k6 harness that hits a **dedicated load-test wedding** only, tags created data with a run id, writes reports under `loadtest/results/<RUN_ID>/`, and surgically deletes only those tagged records/assets.

## Prerequisites

1. Install k6: `brew install k6`
2. Create a dedicated wedding (e.g. slug `loadtest`) with disposable camera accepting photos enabled
3. Set on the **app** (production/staging env):

```bash
LOADTEST_WEDDING_ID=loadtest
```

Without this, the `X-Vowd-Loadtest-Run` header is ignored and uploads are not tagged for cleanup.

## Tagging

| Data | Marker |
|------|--------|
| Dispo photos / S3 keys | `…/photos/lt/<RUN_ID>/…` |
| Save-the-date signups | `lt-<RUN_ID>-*@loadtest.vowd.invalid` |

Unprefixed photos and real guest emails on the loadtest wedding are never deleted by cleanup.

## Run a test

From your laptop (against the dedicated tenant host):

```bash
export BASE_URL=https://loadtest.vowd.site   # or http://loadtest.vowd.localhost:3003

# Convenience wrapper (creates results dir, sets RUN_ID)
SCENARIO=mixed VUS=10 DURATION=30s ./loadtest/bin/run
```

Or via Rake:

```bash
BASE_URL=https://loadtest.vowd.site VUS=10 DURATION=30s \
  bin/rails loadtest:run SCENARIO=mixed
```

Or raw k6:

```bash
export RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)-$RANDOM
mkdir -p loadtest/results/$RUN_ID

k6 run \
  --out json=loadtest/results/$RUN_ID/raw.json \
  -e RUN_ID=$RUN_ID \
  -e BASE_URL=$BASE_URL \
  -e RESULTS_DIR=loadtest/results/$RUN_ID \
  -e VUS=10 \
  -e DURATION=30s \
  --vus 10 --duration 30s \
  loadtest/k6/scenarios/mixed.js
```

### Scenarios

| Script | What it does |
|--------|----------------|
| `browse.js` | GET home, FAQ, photos, wedding party, save-the-date, dispo, gallery, `/ping` |
| `dispo_upload.js` | Concurrent `POST /dispo/upload` with the loadtest header |
| `mixed.js` | ~55% browse, ~35% upload, ~10% STD signup (default) |

Start with low `VUS`. Uploads hit object storage + DB + Turbo broadcast — that path is usually the bottleneck.

## Results

Each run writes under `loadtest/results/<RUN_ID>/`:

- `summary.txt` / `summary.html` / `summary.json` — latency percentiles, RPS, failures
- `raw.json` — full k6 event stream (if you passed `--out json=…`)

k6 thresholds fail the process when error rate or p95 latency is too high (see `loadtest/k6/lib/config.js`).

## Cleanup

On a host with production DB + storage credentials (or `rails runner` against prod):

```bash
# Dry run (default)
LOADTEST_WEDDING_ID=loadtest bin/rails loadtest:cleanup RUN_ID=20260730T213000Z-1234

# Delete tagged rows + remote objects
LOADTEST_WEDDING_ID=loadtest CONFIRM=yes \
  bin/rails loadtest:cleanup RUN_ID=20260730T213000Z-1234

# All load-test tagged data for that wedding
LOADTEST_WEDDING_ID=loadtest CONFIRM=yes \
  bin/rails loadtest:cleanup RUN_ID=all
```

Cleanup refuses any wedding that does not match `LOADTEST_WEDDING_ID`.
