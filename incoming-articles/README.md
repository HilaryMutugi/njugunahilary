# Incoming articles

Use this folder as the drop zone for each new Founder Note before publishing.

Recommended files for each article:

- `article.txt` - the article body, with blank lines between paragraphs
- `image.webp` - the optimized article cover image
- `article.pdf` - optional original document to offer as a download

Then run the publishing script from PowerShell at the website folder:

```powershell
cd D:\Hilary\njuguna-hilary-website
.\scripts\publish-founder-note.ps1 `
  -Title "Your Article Title" `
  -Excerpt "One strong sentence that describes the article." `
  -ArticleFile ".\incoming-articles\article.txt" `
  -ImageFile ".\incoming-articles\image.webp"
```

The publication date defaults to today. The script validates the inputs, calculates reading time, prepares the page, updates the article registry and sitemap, and keeps the homepage current automatically.

It does not commit or push automatically. Preview first, then commit and push when it looks right.

To attach a PDF or preserve an earlier publication link, add either option:

```powershell
-PdfFile ".\incoming-articles\article.pdf"
-OriginalUrl "https://medium.com/@your-original-article"
```

Add `-ValidateOnly` to test a publication without changing any website files.
