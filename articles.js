/**
 * ============================================================
 *  FOUNDER NOTES — Article Registry
 *  njugunahilary.com
 * ============================================================
 *
 *  THIS IS THE ONLY FILE YOU EDIT WHEN PUBLISHING A NEW ARTICLE.
 *
 *  Steps when you publish:
 *  1. Upload your new article HTML file to GitHub
 *  2. Add one new entry at the TOP of the ARTICLES array below
 *  3. Save articles.js and upload it to GitHub too
 *
 *  Done — the homepage cards, archive page, and prev/next
 *  navigation all update automatically.
 *
 *  Keep newest articles at the TOP.
 * ============================================================
 *
 *  ⚠ UPDATE THE DATES for the older articles below.
 *    They currently have estimated dates. Replace them with
 *    the real dates you actually published each article.
 * ============================================================
 */

const ARTICLES = [{
    slug: "founder-notes-when-the-dream-is-no-longer-yours-alone.html",
    title: "When the Dream Is No Longer Yours Alone",
    description: "For a long time, the dream was almost entirely mine to hold. Something has shifted lately, and I think it is worth writing about honestly.",
    date: "June 18, 2026",
    dateISO: "2026-06-18"
  },

  // ─── NEWEST ARTICLE (just uploaded) ────────────────────
  {
    title: "I Built a Website on My Phone at 2am",
    slug: "founder-notes-i-built-a-website-on-my-phone.html",
    date: "June 15, 2026",
    dateISO: "2026-06-15",
    excerpt: "Three nights. My phone. Zero developers. Less than six dollars. Here is what happened when I decided to stop waiting and just build.",
    tag: "Founder Notes"
  },

  // ─── EXISTING ARTICLES ─────────────────────────────────
  // ⚠ Replace the dates below with the real dates you published each one.

  {
    title: "Building in Public, But Honestly",
    slug: "founder-notes-building-in-public.html",
    date: "May 2026",           // ← replace with real date, e.g. "May 12, 2026"
    dateISO: "2026-05-01",      // ← replace with real date, e.g. "2026-05-12"
    excerpt: "For a long time, I thought building a business meant waiting until everything looked polished. Entrepreneurship has taught me something different.",
    tag: "Founder Notes"
  },

  {
    title: "What Keeps Me Awake at Night: Meeting With Destiny",
    slug: "founder-notes-meeting-with-destiny.html",
    date: "April 2026",         // ← replace with real date
    dateISO: "2026-04-01",      // ← replace with real date
    excerpt: "A 1:55am reflection on a decade of dreaming, the lows that almost ended Afrifama, and a meeting that could change everything.",
    tag: "Founder Notes"
  },

  {
    title: "Silence Never Ends a Story",
    slug: "founder-notes-silence-never-ends-a-story.html",
    date: "March 2026",         // ← replace with real date
    dateISO: "2026-03-01",      // ← replace with real date
    excerpt: "A founder's annual reflection on slow growth, an angel investor, The Alchemist, and what building quietly in Sub-Saharan Africa really feels like.",
    tag: "Founder Notes"
  }

];


/* ============================================================
   DO NOT EDIT BELOW THIS LINE
   Helper functions used by index.html, founder-notes.html,
   and individual article pages.
   ============================================================ */

function getArticleBySlug(slug) {
  return ARTICLES.find(a => a.slug === slug) || null;
}

function getAdjacentArticles(slug) {
  const idx = ARTICLES.findIndex(a => a.slug === slug);
  if (idx === -1) return { prev: null, next: null };
  return {
    prev: ARTICLES[idx - 1] || null,
    next: ARTICLES[idx + 1] || null
  };
}

function renderArticleCards(containerId, limit) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const list = limit ? ARTICLES.slice(0, limit) : ARTICLES;
  container.innerHTML = list.map((article, i) => `
    <a class="ncard" href="${article.slug}" style="animation-delay:${i * 0.07}s">
      <span class="cat">${article.tag} &middot; <time datetime="${article.dateISO}">${article.date}</time><span class="rt">${article.readTime || estimateReadTime(article.excerpt)}</span></span>
      <h3>${article.title}</h3>
      <span class="m">${article.excerpt} &rarr;</span>
    </a>
  `).join('');
}

function estimateReadTime(text) {
  const words = (text || '').trim().split(/\s+/).length;
  const minutes = Math.max(1, Math.round(words / 45));
  return `${minutes} min read`;
}

function renderArticleNav(containerId, currentSlug) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const { prev, next } = getAdjacentArticles(currentSlug);
  container.innerHTML = `
    <div class="art-nav">
      ${next ? `
        <a href="${next.slug}" class="art-nav-link art-nav-older">
          <span class="art-nav-label">&larr; Older</span>
          <span class="art-nav-title">${next.title}</span>
        </a>` : '<div></div>'}
      <a href="founder-notes.html" class="art-nav-all">All Notes</a>
      ${prev ? `
        <a href="${prev.slug}" class="art-nav-link art-nav-newer">
          <span class="art-nav-label">Newer &rarr;</span>
          <span class="art-nav-title">${prev.title}</span>
        </a>` : '<div></div>'}
    </div>
  `;
}
