// Keep Founder Notes links in the HTML so readers and crawlers can find them without JavaScript.
// Usage: node scripts/render-article-links.js [articles.js] [index.html] [founder-notes.html]
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = path.resolve(__dirname, '..');
const [registryPath, homePath, notesPath] = [
  process.argv[2] || path.join(root, 'articles.js'),
  process.argv[3] || path.join(root, 'index.html'),
  process.argv[4] || path.join(root, 'founder-notes.html')
];
const registry = fs.readFileSync(registryPath, 'utf8');
const articles = vm.runInNewContext(`${registry}\nARTICLES`);
const escapeHtml = value => String(value || '').replace(/[&<>"']/g, char => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
})[char]);
const safePath = value => {
  if (!/^(?:founder-notes-[a-z0-9-]+\.html|images\/[a-z0-9._-]+)$/i.test(value)) {
    throw new Error(`Unexpected article path: ${value}`);
  }
  return value;
};
const homeCards = articles.slice(0, 3).map((article, i) => `
<a class="ncard" href="${safePath(article.slug)}" style="animation-delay:${i * 0.07}s">
  ${article.image ? `<span class="ncard-img"><img src="${safePath(article.image)}" alt="" loading="lazy"></span>` : ''}
  <span class="ncard-body">
    <span class="cat">${escapeHtml(article.tag)} &middot; <time datetime="${escapeHtml(article.dateISO)}">${escapeHtml(article.date)}</time><span class="rt">${escapeHtml(article.readTime)}</span></span>
    <h3>${escapeHtml(article.title)}</h3>
    <span class="m">${escapeHtml(article.excerpt)} &rarr;</span>
  </span>
</a>`).join('');
const noteCards = articles.map((article, i) => `
<div class="fn-item" style="animation-delay:${i * 0.07}s">
  <div class="fn-main">
    <div class="fn-meta"><span class="fn-tag">${escapeHtml(article.tag)}</span><time class="fn-date" datetime="${escapeHtml(article.dateISO)}">${escapeHtml(article.date)}</time><span class="fn-rt">${escapeHtml(article.readTime)}</span></div>
    <h2 class="fn-title"><a href="${safePath(article.slug)}">${escapeHtml(article.title)}</a></h2>
    <p class="fn-excerpt">${escapeHtml(article.excerpt)}</p>
    <div class="fn-read"><a href="${safePath(article.slug)}">Read the full note &rarr;</a></div>
  </div>${article.image ? `
  <a class="fn-thumb" href="${safePath(article.slug)}"><img src="${safePath(article.image)}" alt="" loading="lazy"></a>` : ''}
</div>`).join('');

function update(file, start, end, markup) {
  const html = fs.readFileSync(file, 'utf8');
  const before = html.indexOf(start);
  const after = html.indexOf(end, before + start.length);
  if (before < 0 || after < 0) throw new Error(`Missing article markers in ${file}`);
  const result = html.slice(0, before + start.length) + markup + html.slice(after);
  fs.writeFileSync(file, result, 'utf8');
}

update(homePath, '<!-- ARTICLE_HOME_START -->', '<!-- ARTICLE_HOME_END -->', homeCards);
update(notesPath, '<!-- ARTICLE_LIST_START -->', '<!-- ARTICLE_LIST_END -->', noteCards);

const notes = fs.readFileSync(notesPath, 'utf8')
  .replace(/(<p class="articles-count" id="articles-count">)[^<]*(<\/p>)/, `$1${articles.length} articles$2`)
  .replace(/(<div class="hero-note"><b>)[^<]*(<\/b>)/, `$1${articles.length}$2`);
fs.writeFileSync(notesPath, notes, 'utf8');

let home = fs.readFileSync(homePath, 'utf8')
  .replace(/(<div class="notes-badge"><b id="notes-count">)[^<]*(<\/b>)/, `$1${articles.length}$2`);
const [latest, second, third] = articles;
if (latest) {
  home = home
    .replace(/(<a class="notes-feature" id="notes-latest" href=")[^"]+/, `$1${safePath(latest.slug)}`)
    .replace(/(<img id="notes-latest-image" src=")[^"]+/, `$1${safePath(latest.image)}`)
    .replace(/(<img id="notes-latest-image"[^>]* alt=")[^"]+/, `$1Cover image for ${escapeHtml(latest.title)}`);
}
for (const [id, article] of [['notes-secondary-one', second], ['notes-secondary-two', third]]) {
  if (!article) continue;
  const pattern = new RegExp(`(<a id="${id}" href=")[^"]+("[^>]*><img src=")[^"]+`);
  home = home.replace(pattern, `$1${safePath(article.slug)}$2${safePath(article.image)}`);
}
fs.writeFileSync(homePath, home, 'utf8');
