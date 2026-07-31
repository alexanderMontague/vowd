import http from "k6/http";
import { check, sleep } from "k6";
import { FormData } from "https://jslib.k6.io/formdata/0.0.2/index.js";

const LOADTEST_HEADER = "X-Vowd-Loadtest-Run";

export function getPage(baseUrl, path, endpoint) {
  const res = http.get(`${baseUrl}${path}`, {
    tags: { endpoint },
    redirects: 5,
  });
  check(res, {
    [`${endpoint} status ok`]: (r) => r.status >= 200 && r.status < 500,
  });
  return res;
}

export function uploadDispoPhoto(baseUrl, runId, imageBytes, endpoint = "dispo_upload") {
  const form = new FormData();
  form.append("photo", http.file(imageBytes, "tiny.jpg", "image/jpeg"));
  form.append("flash_enabled", "false");
  form.append("captured_at", new Date().toISOString());

  const res = http.post(`${baseUrl}/dispo/upload`, form.body(), {
    headers: {
      "Content-Type": `multipart/form-data; boundary=${form.boundary}`,
      [LOADTEST_HEADER]: runId,
    },
    tags: { endpoint },
  });

  check(res, {
    "dispo upload created": (r) => r.status === 201,
  });
  return res;
}

export function signupSaveTheDate(baseUrl, runId, n, endpoint = "std_signup") {
  const email = `lt-${runId}-${n}@loadtest.vowd.invalid`;
  const payload = {
    "save_the_date_signup[name]": `Load Tester ${n}`,
    "save_the_date_signup[email]": email,
    "save_the_date_signup[phone_number]": "",
  };

  const res = http.post(`${baseUrl}/save-the-date`, payload, {
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    tags: { endpoint },
    redirects: 0,
  });

  check(res, {
    "std signup redirected or ok": (r) => r.status === 302 || r.status === 200,
  });
  return res;
}

export function think(seconds = 0.3) {
  sleep(seconds);
}
