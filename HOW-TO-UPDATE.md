# How to update your website

Plain-English guide. No coding needed — just a **text editor** (Notepad, TextEdit, or the free **VS Code**) and a browser.

---

## What's in this folder

```
index.html                              ← homepage
about.html                              ← your About page (story, podcast, gallery)
founder-notes-building-in-public.html   ← your first article
article-template.html                   ← copy this to write new articles
hilary-story-how-to-raise-capital.m4a   ← your podcast audio (plays on the About page)
favicon.svg                             ← the little "NH" browser-tab icon
social-preview.jpg                      ← image shown when you share your link
images/                                 ← ALL your photos
HOW-TO-UPDATE.md                        ← this guide
```

**Golden rule:** keep every file in one folder and always upload the whole folder together. The pages find the images, the podcast, and each other by being neighbours.

---

## 1. Change a photo

Every photo is a file in the **images** folder. Replace the file with your new photo using the **exact same name**, and it updates automatically.

**Homepage photos**

| File | Where it appears |
|---|---|
| `hero.jpg`     | Top banner (golden field) |
| `meet.jpg`     | "Meet Me" (you writing) |
| `grad.jpg`     | Journey → "The Beginning" (graduation) |
| `afrifama.jpg` | Journey → "Building Afrifama" |
| `digital.jpg`  | Journey → "Going Digital" |
| `farmers.jpg`  | Journey → "What's Next" |
| `notes.jpg`    | "Founder Notes" side photo |
| `speak.jpg`    | "Speaking" (you presenting) |
| `closing.jpg`  | Bottom "Work With Me" banner |

**About-page photos** (all start with `about-`)

| File | Where it appears |
|---|---|
| `about-intro.jpg` | Top portrait |
| `about-today.jpg` | "Afrifama today" |
| `about-turn.jpg`  | "The turning point" (feed bags) |
| `about-speak.jpg` | "Beyond Afrifama" |
| `about-g1…g4.jpg` | The "Moments" gallery |

Tips: keep the filename identical (lowercase, `.jpg`); banner photos ~1500px wide, others ~1000px; if a photo looks sideways, open it, rotate, re-save, then add it.

---

## 2. Edit any text

1. Open `index.html` or `about.html` in your text editor.
2. **Find** (Ctrl/Cmd+F) the words you want to change.
3. Type new words **between** the `>` and `<` symbols, e.g. change
   `<h2>First, a proper introduction.</h2>` → only the middle part.
4. Save, then open the file in a browser to check.

Leave the symbols (`<p>`, `&mdash;`, `&amp;`) alone — just edit the plain words. `&mdash;` shows as —, `&amp;` shows as &.

---

## 3. Add a new article (Founder Note)

1. **Copy** `article-template.html`, rename it like `founder-notes-lessons-from-afrifama.html` (lowercase, hyphens).
2. Open it, follow the instructions at the top, replace the title/category/headline/paragraphs. Save.
3. **Link it from the homepage:** open `index.html`, search for "Lessons from Afrifama" (or "What Keeps Me Up at Night"), then on that card change `href="#"` to your new file name and `Coming soon` to `Published here`.
4. Save and upload.

---

## 4. Change a Watch video

The Watch section pulls each video's cover straight from YouTube using its **video ID**. To swap a video, open `index.html`, find the old ID (search the part after `youtu.be/` or `vi/`, e.g. `kSogx_GQKpI`) and replace **every** copy of it with your new video's ID. The featured (top) video's ID also appears once more near the bottom in a line starting with `var yth` — replace it there too.

---

## 5. Change the podcast

Replace `hilary-story-how-to-raise-capital.m4a` with your new audio file using the same name. (Or to use a different name, open `about.html`, search for the filename, and update it there.)

---

## 6. Change a link or your email

Open the file, search for the old link (e.g. `hello@njugunahilary.com` or `youtube.com/@Afrifama`), and type the new one. Find-and-Replace-All updates every copy at once.

---

## 7. Put it online (and update it later)

**First time:**
1. Go to **netlify.com** (or vercel.com / pages.cloudflare.com) and make a free account.
2. "Add new site" → **drag this whole folder** onto the page.
3. You get a live link instantly. Later you can add your own domain in the settings.

**To update:** edit locally, then drag the folder onto the same site again ("Deploys → drag and drop"). It replaces the old version.

> Once you have a domain, open `index.html`, `about.html`, and the article, search for `njugunahilary.com`, and replace it with your real domain so link-previews point to the right place.

---

## A safety habit

Before any big edit, **copy the whole folder first.** If something breaks, go back to the copy. That's your whole backup plan.

That's it — the full site (homepage, About, article, podcast) is yours to run.
