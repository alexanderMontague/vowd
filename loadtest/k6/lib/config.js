import { textSummary } from "https://jslib.k6.io/k6-summary/0.1.0/index.js";

const DEFAULT_BASE_URL = "http://loadtest.vowd.localhost:3003";

export function loadConfig() {
  const runId = (__ENV.RUN_ID || "").trim();
  if (!runId) {
    throw new Error("RUN_ID is required (e.g. 20260730T213000Z-abc123)");
  }
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(runId)) {
    throw new Error(`Invalid RUN_ID: ${runId}`);
  }

  const baseUrl = (__ENV.BASE_URL || DEFAULT_BASE_URL).replace(/\/$/, "");
  const vus = Number(__ENV.VUS || 10);
  const duration = __ENV.DURATION || "30s";
  const resultsDir = __ENV.RESULTS_DIR || `loadtest/results/${runId}`;

  return {
    runId,
    baseUrl,
    vus,
    duration,
    resultsDir,
    options: {
      vus,
      duration,
      thresholds: {
        http_req_failed: ["rate<0.05"],
        http_req_duration: ["p(95)<5000"],
        "http_req_duration{endpoint:dispo_upload}": ["p(95)<15000"],
      },
      summaryTrendStats: ["avg", "min", "med", "p(90)", "p(95)", "p(99)", "max"],
      tags: {
        run_id: runId,
      },
    },
  };
}

export function writeSummary(data, resultsDir, runId) {
  const summaryPath = `${resultsDir}/summary`;
  return {
    stdout: textSummary(data, { indent: " ", enableColors: true }),
    [`${summaryPath}.json`]: JSON.stringify(data, null, 2),
    [`${summaryPath}.txt`]: textSummary(data, { indent: " ", enableColors: false }),
    [`${summaryPath}.html`]: htmlReport(data, runId),
  };
}

function htmlReport(data, runId) {
  const metrics = data.metrics || {};
  const rows = Object.keys(metrics)
    .sort()
    .map((name) => {
      const m = metrics[name];
      const values = m.values || {};
      const bits = Object.keys(values)
        .map((k) => `${k}=${formatValue(values[k])}`)
        .join(", ");
      return `<tr><td>${escapeHtml(name)}</td><td>${escapeHtml(bits)}</td></tr>`;
    })
    .join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Vowd load test ${escapeHtml(runId)}</title>
  <style>
    body { font-family: ui-sans-serif, system-ui, sans-serif; margin: 2rem; color: #111; }
    h1 { font-size: 1.4rem; }
    table { border-collapse: collapse; width: 100%; margin-top: 1rem; }
    th, td { border: 1px solid #ddd; padding: 0.5rem 0.75rem; text-align: left; vertical-align: top; }
    th { background: #f4f4f4; }
    td:first-child { white-space: nowrap; font-family: ui-monospace, monospace; }
  </style>
</head>
<body>
  <h1>Vowd load test — ${escapeHtml(runId)}</h1>
  <p>Inspect latency percentiles and error rates below. Slow or failing tagged endpoints show where the site struggled.</p>
  <table>
    <thead><tr><th>Metric</th><th>Values</th></tr></thead>
    <tbody>
${rows}
    </tbody>
  </table>
</body>
</html>
`;
}

function formatValue(value) {
  if (typeof value === "number") {
    return Number.isInteger(value) ? String(value) : value.toFixed(3);
  }
  return String(value);
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
