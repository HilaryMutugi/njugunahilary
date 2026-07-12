/**
 * ============================================================
 *  FOUNDER NOTES -- Article Registry
 *  njugunahilary.com
 * ============================================================
 *
 *  Publish with scripts/publish-founder-note.ps1. The helper adds the
 *  newest entry here after validating the article, image, metadata,
 *  reading time, and sitemap. See HOW-TO-UPDATE.md for the short guide.
 *
 *  Keep newest articles at the TOP.
 * ============================================================
 *
 *  ⚠ UPDATE THE DATES for the older articles below.
 *    They currently have estimated dates. Replace them with
 *    the real dates you actually published each article.
 * ============================================================
 */

const ARTICLES = [
  // NEWEST ARTICLE
  {
    title: "What Keeps Me Up at Night: The Idea Waited for Us to Grow",
    slug: "founder-notes-the-idea-waited-for-us-to-grow.html",
    date: "July 12, 2026",
    dateISO: "2026-07-12",
    excerpt: "A reflection on an early idea called Kukuza, the lessons that shaped Afrifama, and the 205 farmers now waiting for the dream to grow.",
    tag: "Founder Notes",
    image: "images/about-afrifama-partnership.jpg",
    readTime: "4 min read"
  },

  {
    title: "Did I Just Become Dangerous Overnight?",
    slug: "founder-notes-did-i-just-become-dangerous-overnight.html",
    date: "July 6, 2026",
    dateISO: "2026-07-06",
    excerpt: "A 2am Founder Note on building two websites in one weekend, identity, belief, and deciding who you are before anyone gives you permission.",
    tag: "Founder Notes",
    image: "images/founder-notes-did-i-just-become-dangerous-overnight.webp",
    readTime: "5 min read"
  },

  {
    slug: "founder-notes-light-bulb-moment.html",
    title: "What Nobody Tells You About the Light Bulb Moment",
    date: "July 3, 2026",
    dateISO: "2026-07-03",
    excerpt: "Nobody tells you when the light bulb moment is coming. It shows up disguised as exhaustion, a rejected phone call, and a business plan you keep going back to at 9pm.",
    tag: "Founder Notes",
    image: "images/light-bulb-moment.webp",
    readTime: "6 min read"
  },
  {
    title: "Belief",
    slug: "founder-notes-belief.html",
    date: "June 21, 2026",
    dateISO: "2026-06-21",
    excerpt: "On stubborn belief, two underdog football wins, and building a real farmers' platform from scratch &mdash; one 3am commit at a time.",
    tag: "Founder Notes",
    image: "images/founder-notes-belief.webp",
    readTime: "3 min read"
  },

  {
    title: "Proof of Life",
    slug: "founder-notes-proof-of-life.html",
    date: "June 20, 2026",
    dateISO: "2026-06-20",
    excerpt: "205 farmer applications, a website built on a phone, and the quiet admiration in mentoring rooms I rarely talk about. An honest proof of life from the road.",
    tag: "Founder Notes",
    image: "images/founder-notes-proof-of-life.webp",
    readTime: "3 min read"
  },

  {
    title: "When the Dream Is No Longer Yours Alone",
    slug: "founder-notes-when-the-dream-is-no-longer-yours-alone.html",
    date: "June 18, 2026",
    dateISO: "2026-06-18",
    excerpt: "For a long time, the dream was almost entirely mine to hold. Something has shifted lately, and I think it is worth writing about honestly.",
    tag: "Founder Notes",
    image: "images/founder-notes-dream-no-longer-yours-alone.webp",
    readTime: "5 min read"
  },

  {
    title: "I Built a Website on My Phone at 2am",
    slug: "founder-notes-i-built-a-website-on-my-phone.html",
    date: "June 15, 2026",
    dateISO: "2026-06-15",
    excerpt: "Three nights. My phone. Zero developers. Less than six dollars. Here is what happened when I decided to stop waiting and just build.",
    tag: "Founder Notes",
    image: "images/founder-notes-website-on-phone.webp",
    readTime: "5 min read"
  },

  // ─── EXISTING ARTICLES ─────────────────────────────────
  // ⚠ Replace the dates below with the real dates you published each one.

  {
    title: "Building in Public, But Honestly",
    slug: "founder-notes-building-in-public.html",
    date: "May 2026",           // ← replace with real date, e.g. "May 12, 2026"
    dateISO: "2026-05-01",      // ← replace with real date, e.g. "2026-05-12"
    excerpt: "For a long time, I thought building a business meant waiting until everything looked polished. Entrepreneurship has taught me something different.",
    tag: "Founder Notes",
    image: "images/founder-notes-building-in-public.webp",
    readTime: "1 min read"
  },

  {
    title: "What Keeps Me Awake at Night: Meeting With Destiny",
    slug: "founder-notes-meeting-with-destiny.html",
    date: "April 2026",         // ← replace with real date
    dateISO: "2026-04-01",      // ← replace with real date
    excerpt: "A 1:55am reflection on a decade of dreaming, the lows that almost ended Afrifama, and a meeting that could change everything.",
    tag: "Founder Notes",
    image: "images/founder-notes-meeting-with-destiny.webp",
    readTime: "3 min read"
  },

  {
    title: "Silence Never Ends a Story",
    slug: "founder-notes-silence-never-ends-a-story.html",
    date: "March 2026",         // ← replace with real date
    dateISO: "2026-03-01",      // ← replace with real date
    excerpt: "A founder's annual reflection on slow growth, an angel investor, The Alchemist, and what building quietly in Sub-Saharan Africa really feels like.",
    tag: "Founder Notes",
    image: "images/founder-notes-silence-never-ends-a-story.webp",
    readTime: "5 min read"
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
      ${article.image ? `<span class="ncard-img"><img src="${article.image}" alt="" loading="lazy"></span>` : ''}
      <span class="ncard-body">
        <span class="cat">${article.tag} &middot; <time datetime="${article.dateISO}">${article.date}</time><span class="rt">${article.readTime || estimateReadTime(article.excerpt)}</span></span>
        <h3>${article.title}</h3>
        <span class="m">${article.excerpt} &rarr;</span>
      </span>
    </a>
  `).join('');
}

function estimateReadTime(text) {
  const words = (text || '').trim().split(/\s+/).length;
  const minutes = Math.max(1, Math.ceil(words / 220));
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
