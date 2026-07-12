# Incoming articles

Use this folder as the drop zone for each new Founder Note before publishing.

Recommended files for each article:

- `article.pdf` - the article body and original PDF
- `image.png` or `image.jpg` - the article cover image

Then run the publishing script from PowerShell at the website folder:

```powershell
cd D:\Hilary\njuguna-hilary-website
.\scripts\publish-founder-note.ps1 `
  -Title "Your Article Title" `
  -Date "2026-07-06" `
  -Excerpt "One strong sentence that describes the article." `
  -ArticleFile ".\incoming-articles\article.pdf" `
  -ImageFile ".\incoming-articles\image.png"
```

The script prepares the page, copies the image/PDF, updates `articles.js`, and updates `sitemap.xml`.

It does not commit or push automatically. Preview first, then commit and push when it looks right.

If the PDF is scanned or image-only, the script may not be able to extract the text. In that case, paste the article into `article.txt` and run the same command with:

```powershell
-ArticleFile ".\incoming-articles\article.txt" -PdfFile ".\incoming-articles\article.pdf"
```
