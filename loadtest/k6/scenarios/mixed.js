import { loadConfig, writeSummary } from "../lib/config.js";
import { getPage, signupSaveTheDate, think, uploadDispoPhoto } from "../lib/http.js";

const config = loadConfig();
export const options = config.options;

const imageBytes = open("../../fixtures/tiny.jpg", "b");

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
  const roll = Math.random();

  if (roll < 0.55) {
    const [path, endpoint] = BROWSE_PATHS[Math.floor(Math.random() * BROWSE_PATHS.length)];
    getPage(config.baseUrl, path, endpoint);
  } else if (roll < 0.9) {
    uploadDispoPhoto(config.baseUrl, config.runId, imageBytes);
  } else {
    const n = `${__VU}-${__ITER}`;
    signupSaveTheDate(config.baseUrl, config.runId, n);
  }

  think(0.25);
}

export function handleSummary(data) {
  return writeSummary(data, config.resultsDir, config.runId);
}
