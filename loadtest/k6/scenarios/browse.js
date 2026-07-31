import { loadConfig, writeSummary } from "../lib/config.js";
import { getPage, think } from "../lib/http.js";

const config = loadConfig();
export const options = config.options;

const BROWSE_PATHS = [
  ["/", "home"],
  ["/faq", "faq"],
  ["/photos", "photos"],
  ["/wedding-party", "wedding_party"],
  ["/save-the-date", "save_the_date"],
  ["/dispo", "dispo_camera"],
  ["/dispo/gallery", "dispo_gallery"],
  ["/ping", "ping"],
];

export default function () {
  const [path, endpoint] = BROWSE_PATHS[Math.floor(Math.random() * BROWSE_PATHS.length)];
  getPage(config.baseUrl, path, endpoint);
  think(0.2);
}

export function handleSummary(data) {
  return writeSummary(data, config.resultsDir, config.runId);
}
