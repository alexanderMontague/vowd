const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = "/Users/alexmontague/Desktop/Alex/code/vowd";
const OUT = path.join(ROOT, "app/assets/images/marketing");
const TMP = "/tmp/vowd-marketing-shots";
const BASE = process.env.APP_BASE_DOMAIN || "vowd.localhost";
const PORT = process.env.APP_PORT || "3003";
const SLUG = "britt-and-alex";
const HOST = `http://${SLUG}.${BASE}:${PORT}`;

fs.mkdirSync(TMP, { recursive: true });
fs.mkdirSync(OUT, { recursive: true });

async function waitForFonts(page) {
  await page.evaluate(async () => {
    if (document.fonts && document.fonts.ready) {
      await document.fonts.ready;
    }
  });
  await page.waitForTimeout(400);
}

async function settleInvitationPage(page) {
  await waitForFonts(page);
  // Warm layout + floating parallax by scrolling through the page, then settle
  // where framed content + floating photos read clearly.
  await page.evaluate(async () => {
    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    const maxY = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
    const steps = [0.12, 0.28, 0.48, 0.68, 0.88, 1];
    for (const fraction of steps) {
      window.scrollTo(0, Math.round(maxY * fraction));
      await delay(240);
    }
    window.scrollTo(0, Math.round(Math.min(maxY * 0.14, 220)));
  });
  await page.waitForTimeout(600);
  await waitForFonts(page);
}

async function shot(page, url, file, { invitation = false } = {}) {
  await page.goto(url, { waitUntil: "networkidle", timeout: 45000 });
  await waitForFonts(page);
  if (invitation) {
    await settleInvitationPage(page);
  } else {
    await page.waitForTimeout(700);
  }
  const dest = path.join(TMP, file);
  await page.screenshot({ path: dest, fullPage: false });
  console.log("wrote", dest);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });

  await shot(page, `${HOST}/`, "hero.png");
  await shot(page, `${HOST}/rsvp?skip_video=1`, "rsvp.png", { invitation: true });
  await shot(page, `${HOST}/save-the-date?skip_video=1`, "save-the-date.png", {
    invitation: true,
  });

  await page.goto(`${HOST}/admin/login`, { waitUntil: "networkidle" });
  await page.fill("input[name='email'], input[type='email']", "demo@vowd.test");
  await page.fill("input[name='password'], input[type='password']", "password");
  await Promise.all([
    page.waitForNavigation({ waitUntil: "networkidle" }),
    page.click("input[type='submit'], button[type='submit']"),
  ]);
  console.log("logged in", page.url());

  await shot(page, `${HOST}/admin`, "admin.png");
  await shot(page, `${HOST}/admin/theme/home`, "theme.png");
  await shot(page, `${HOST}/admin/party`, "party.png");

  await browser.close();

  const map = {
    "hero.png": "hero.jpg",
    "admin.png": "admin.jpg",
    "theme.png": "theme.jpg",
    "rsvp.png": "rsvp.jpg",
    "save-the-date.png": "save-the-date.jpg",
    "party.png": "party.jpg",
  };

  for (const [src, dest] of Object.entries(map)) {
    const from = path.join(TMP, src);
    const to = path.join(OUT, dest);
    execFileSync("magick", [from, "-resize", "1600x>", "-quality", "84", to]);
    console.log("exported", to);
  }

  const dispo = path.join(ROOT, "db/seed_assets/dispo.jpg");
  if (fs.existsSync(dispo)) {
    const to = path.join(OUT, "gallery.jpg");
    execFileSync("magick", [dispo, "-resize", "1600x>", "-quality", "84", to]);
    console.log("exported", to, "from seed dispo");
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
