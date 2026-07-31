import { loadConfig, writeSummary } from "../lib/config.js";
import { uploadDispoPhoto, think } from "../lib/http.js";

const config = loadConfig();
export const options = {
  ...config.options,
  thresholds: {
    ...config.options.thresholds,
    http_req_failed: ["rate<0.10"],
  },
};

const imageBytes = open("../../fixtures/tiny.jpg", "b");

export default function () {
  uploadDispoPhoto(config.baseUrl, config.runId, imageBytes);
  think(0.5);
}

export function handleSummary(data) {
  return writeSummary(data, config.resultsDir, config.runId);
}
