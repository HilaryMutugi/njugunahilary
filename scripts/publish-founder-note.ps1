param(
  [Parameter(Mandatory=$true)]
  [string]$Title,

  [Parameter(Mandatory=$true)]
  [string]$Date,

  [Parameter(Mandatory=$true)]
  [string]$Excerpt,

  [Parameter(Mandatory=$true)]
  [string]$ArticleFile,

  [Parameter(Mandatory=$true)]
  [string]$ImageFile,

  [string]$PdfFile = "",
  [string]$Category = "Founder Notes",
  [string]$HeroAlt = "",
  [string]$Slug = "",
  [switch]$OpenPreview
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
  $current = (Get-Location).Path
  while ($current) {
    if (Test-Path -LiteralPath (Join-Path $current ".git")) { return $current }
    $parent = Split-Path -Parent $current
    if ($parent -eq $current) { break }
    $current = $parent
  }
  throw "Run this script from inside the website folder."
}

function Convert-ToSlug([string]$value) {
  $s = $value.ToLowerInvariant()
  $s = $s -replace "&", " and "
  $s = $s -replace "[^a-z0-9]+", "-"
  $s = $s.Trim("-")
  if (-not $s) { throw "Could not create a slug from the title." }
  return "founder-notes-$s"
}

function Convert-ToDisplayDate([datetime]$value) {
  return $value.ToString("MMMM d, yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
}

function Convert-ToIsoDate([datetime]$value) {
  return $value.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
}

function Escape-Html([string]$value) {
  return [System.Net.WebUtility]::HtmlEncode($value)
}

function Escape-Js([string]$value) {
  return ($value -replace "\\", "\\\\" -replace '"', '\"' -replace "`r?`n", " ")
}

function Get-CommandPath([string[]]$names) {
  foreach ($name in $names) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  return $null
}

function Convert-PdfToText([string]$pdfPath) {
  $pdftotext = Get-CommandPath @("pdftotext")
  if ($pdftotext) {
    $output = & $pdftotext -layout -enc UTF-8 $pdfPath -
    if ($LASTEXITCODE -eq 0 -and ($output -join "`n").Trim()) {
      return ($output -join "`n")
    }
  }

  $python = Get-CommandPath @("py", "python", "python3")
  if ($python) {
    $extractor = @'
import sys
try:
    from pypdf import PdfReader
except Exception:
    try:
        from PyPDF2 import PdfReader
    except Exception as exc:
        print("PDF_EXTRACTION_IMPORT_ERROR:" + str(exc), file=sys.stderr)
        sys.exit(3)

reader = PdfReader(sys.argv[1])
parts = []
for page in reader.pages:
    parts.append(page.extract_text() or "")
text = "\n\n".join(parts).strip()
if not text:
    sys.exit(4)
print(text)
'@
    $tmpPy = Join-Path ([System.IO.Path]::GetTempPath()) "extract-founder-note-pdf.py"
    Set-Content -LiteralPath $tmpPy -Value $extractor -Encoding UTF8

    if ((Split-Path -Leaf $python).ToLowerInvariant() -eq "py.exe" -or (Split-Path -Leaf $python).ToLowerInvariant() -eq "py") {
      $output = & $python -3 $tmpPy $pdfPath
    } else {
      $output = & $python $tmpPy $pdfPath
    }

    if ($LASTEXITCODE -eq 0 -and ($output -join "`n").Trim()) {
      return ($output -join "`n")
    }
  }

  throw "Could not extract text from the PDF. If it is a scanned/image PDF, paste the article text into incoming-articles/article.txt, or install Python with pypdf."
}

function Convert-ArticleTextToHtml([string]$text) {
  $parts = [regex]::Split($text.Trim(), "(\r?\n){2,}") | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "^\r?\n+$" }
  $html = New-Object System.Collections.Generic.List[string]
  $paragraphNumber = 0

  foreach ($raw in $parts) {
    $p = $raw.Trim()
    if ($p -match "^-{3,}$") {
      $html.Add('<hr class="divider">')
      continue
    }

    if ($p.StartsWith("#")) {
      continue
    }

    if ($p.StartsWith(">")) {
      $pull = $p.TrimStart(">").Trim()
      $html.Add("<p class=""pull"">$(Escape-Html $pull)</p>")
      continue
    }

    $paragraphNumber++
    $encoded = Escape-Html ($p -replace "\r?\n", " ")
    if ($paragraphNumber -eq 1) {
      $html.Add("<p class=""lead"">$encoded</p>")
    } else {
      $html.Add("<p>$encoded</p>")
    }
  }

  if ($html.Count -eq 0) {
    throw "The article file did not contain any publishable text."
  }

  return ($html -join "`r`n`r`n")
}

$repo = Resolve-RepoRoot
Set-Location -LiteralPath $repo

$articlePath = Resolve-Path -LiteralPath $ArticleFile
$imagePath = Resolve-Path -LiteralPath $ImageFile
$articleExt = [System.IO.Path]::GetExtension($articlePath.Path).ToLowerInvariant()
if ($articleExt -notin @(".txt",".md",".pdf")) {
  throw "ArticleFile must be a .txt, .md, or .pdf file."
}

$dateValue = [datetime]::Parse($Date, [System.Globalization.CultureInfo]::InvariantCulture)
$dateDisplay = Convert-ToDisplayDate $dateValue
$dateIso = Convert-ToIsoDate $dateValue

if (-not $Slug) { $Slug = Convert-ToSlug $Title }
$htmlFileName = "$Slug.html"
$htmlPath = Join-Path $repo $htmlFileName
if (Test-Path -LiteralPath $htmlPath) { throw "$htmlFileName already exists. Pick another -Slug or title." }

$imageExt = [System.IO.Path]::GetExtension($imagePath.Path).ToLowerInvariant()
if ($imageExt -notin @(".jpg",".jpeg",".png",".webp")) {
  throw "Image must be .jpg, .jpeg, .png, or .webp"
}
$imageFileName = "$Slug$imageExt"
$imageDestRelative = "images/$imageFileName"
$imageDest = Join-Path $repo $imageDestRelative
Copy-Item -LiteralPath $imagePath.Path -Destination $imageDest

$pdfBlock = ""
if ($articleExt -eq ".pdf" -and -not $PdfFile) {
  $PdfFile = $articlePath.Path
}

if ($PdfFile) {
  $pdfPath = Resolve-Path -LiteralPath $PdfFile
  if ([System.IO.Path]::GetExtension($pdfPath.Path).ToLowerInvariant() -ne ".pdf") {
    throw "PdfFile must point to a .pdf file."
  }
  $filesDir = Join-Path $repo "files"
  if (-not (Test-Path -LiteralPath $filesDir)) { New-Item -ItemType Directory -Path $filesDir | Out-Null }
  $pdfFileName = "$Slug.pdf"
  $pdfDestRelative = "files/$pdfFileName"
  Copy-Item -LiteralPath $pdfPath.Path -Destination (Join-Path $repo $pdfDestRelative)
  $pdfBlock = @"

<p><a class="pdf-link" href="$pdfDestRelative" target="_blank" rel="noopener">Read or download the original PDF &rarr;</a></p>
"@
}

if (-not $HeroAlt) { $HeroAlt = $Title }

if ($articleExt -eq ".pdf") {
  Write-Host "Extracting article text from PDF..." -ForegroundColor Yellow
  $rawArticle = Convert-PdfToText $articlePath.Path
} else {
  $rawArticle = Get-Content -LiteralPath $articlePath.Path -Raw -Encoding UTF8
}
$articleHtml = Convert-ArticleTextToHtml $rawArticle
$titleHtml = Escape-Html $Title
$categoryHtml = Escape-Html $Category
$excerptHtml = Escape-Html $Excerpt
$heroAltHtml = Escape-Html $HeroAlt
$ogImage = "https://njugunahilary.com/$imageDestRelative"
$pageUrl = "https://njugunahilary.com/$htmlFileName"

$page = @"
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>$titleHtml — Njuguna Hilary</title>
<meta name="description" content="$excerptHtml">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<meta property="og:type" content="article">
<meta property="og:title" content="$titleHtml — Njuguna Hilary">
<meta property="og:description" content="$excerptHtml">
<meta property="og:image" content="$ogImage">
<meta property="og:url" content="$pageUrl">
<link rel="canonical" href="$pageUrl">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$titleHtml — Njuguna Hilary">
<meta name="twitter:description" content="$excerptHtml">
<meta name="twitter:image" content="$ogImage">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,ital,wght@9..144,0,400;9..144,0,600;9..144,0,700;9..144,1,400&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--charcoal:#211F1C;--ink:#2B2A26;--cream:#F6F1E7;--cream2:#EDE5D4;--green:#3E5C3A;--green-d:#2F4630;--brown:#6F4E37;--gold:#C9A24B;--muted:#7A6F5C;--serif:'Fraunces',Georgia,serif;--sans:'Inter',system-ui,sans-serif;--e:cubic-bezier(.16,1,.3,1)}
*{box-sizing:border-box;margin:0;padding:0}html{scroll-behavior:smooth}
body{font-family:var(--sans);background:var(--cream);color:var(--ink);line-height:1.75;-webkit-font-smoothing:antialiased}
a{color:inherit}h1,h2{font-family:var(--serif);font-weight:600;line-height:1.12;letter-spacing:-.01em}
header{position:sticky;top:0;z-index:20;background:rgba(33,31,28,.95);backdrop-filter:blur(8px)}
nav{display:flex;align-items:center;justify-content:space-between;height:64px;max-width:760px;margin:0 auto;padding:0 26px}
.brand{font-family:var(--serif);font-weight:700;font-size:1.06rem;color:var(--cream)}
nav .back{font-size:.85rem;font-weight:500;color:rgba(246,241,231,.8)}nav .back:hover{color:var(--gold)}
.wrap{max-width:680px;margin:0 auto;padding:0 26px}
.head{padding:64px 0 36px;border-bottom:1px solid rgba(111,78,55,.22);margin-bottom:40px}
.eyebrow{font-size:.7rem;letter-spacing:.22em;text-transform:uppercase;font-weight:600;color:var(--green);display:inline-flex;gap:9px;align-items:center;margin-bottom:18px}.eyebrow::before{content:"";width:24px;height:1.5px;background:var(--gold)}
h1{font-size:clamp(2rem,5.2vw,3rem);margin-bottom:20px}
.byline{display:flex;align-items:center;gap:12px;font-size:.9rem;color:var(--muted);flex-wrap:wrap}
.byline b{color:var(--ink);font-weight:600}.byline .dot{width:4px;height:4px;border-radius:50%;background:var(--gold)}
.article-hero{margin:0 0 40px;border-radius:6px;overflow:hidden;box-shadow:0 28px 70px -46px rgba(33,31,28,.72);background:var(--charcoal)}
.article-hero img{width:100%;display:block;aspect-ratio:16/10;object-fit:cover}
article{padding-bottom:30px;font-size:1.12rem}
article p{margin-bottom:22px}
article p.lead{font-family:var(--serif);font-style:italic;font-size:1.3rem;line-height:1.5;color:var(--green-d)}
article .pull{font-family:var(--serif);font-size:1.5rem;line-height:1.35;color:var(--ink);border-left:3px solid var(--gold);padding:6px 0 6px 22px;margin:34px 0}
article .divider{border:none;border-top:1px solid rgba(111,78,55,.18);margin:36px 0}
.pdf-link{display:inline-flex;margin:8px 0 26px;padding:12px 16px;border:1px solid rgba(62,92,58,.35);border-radius:3px;color:var(--green);font-size:.9rem;font-weight:600;text-decoration:none}.pdf-link:hover{background:var(--green);color:var(--cream)}
.signature{padding:32px 0 36px;border-top:1px solid rgba(111,78,55,.22);text-align:center;font-family:var(--serif)}
.signature .sig-name{font-style:italic;font-size:1.1rem;color:var(--ink);margin-bottom:4px}
.signature .tagline{font-size:.72rem;letter-spacing:.2em;text-transform:uppercase;font-weight:600;color:var(--gold);font-family:var(--sans)}
.foot{margin-top:8px;padding:36px 0 60px;border-top:1px solid rgba(111,78,55,.22)}
.foot .k{font-size:.7rem;letter-spacing:.18em;text-transform:uppercase;color:var(--muted);margin-bottom:14px}
.btn{display:inline-flex;align-items:center;gap:8px;font-size:.92rem;font-weight:600;padding:13px 24px;border-radius:3px;border:1.5px solid var(--green);color:var(--green);transition:.25s var(--e);text-decoration:none}
.btn:hover{background:var(--green);color:var(--cream)}
.foot .links{margin-top:26px;display:flex;flex-wrap:wrap;gap:18px;font-size:.85rem;color:var(--muted)}.foot .links a:hover{color:var(--green)}
.art-nav{display:grid;grid-template-columns:1fr auto 1fr;align-items:center;gap:1.2rem;margin-top:3rem;padding-top:2rem;border-top:1px solid rgba(111,78,55,.22)}
.art-nav-link{text-decoration:none;display:flex;flex-direction:column;gap:4px;transition:opacity .2s}.art-nav-link:hover{opacity:.7}.art-nav-older{align-items:flex-start}.art-nav-newer{align-items:flex-end;text-align:right}
.art-nav-label{font-size:.65rem;font-weight:600;letter-spacing:.16em;text-transform:uppercase;color:var(--gold)}.art-nav-title{font-family:var(--serif);font-size:.9rem;font-weight:600;color:var(--ink);line-height:1.3;max-width:180px}
.art-nav-all{font-size:.72rem;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);text-decoration:none;padding:.45rem .9rem;border:1px solid rgba(122,111,92,.3);border-radius:3px;transition:all .2s;white-space:nowrap}
.art-nav-all:hover{border-color:var(--gold);color:var(--gold)}
@media(max-width:540px){.art-nav{grid-template-columns:1fr 1fr;grid-template-rows:auto auto}.art-nav-all{grid-column:1/-1;text-align:center;order:-1}.art-nav-newer{align-items:flex-end}}
</style><link rel="stylesheet" href="v14.css"></head><body class="article-page">
<header><nav>
<a class="brand" href="index.html">Njuguna&nbsp;Hilary</a>
<a class="back" href="founder-notes.html">&larr; All Founder Notes</a>
</nav></header>
<div class="wrap">
<div class="head">
<span class="eyebrow">Founder Notes &middot; $categoryHtml</span>
<h1>$titleHtml</h1>
<div class="byline"><b>Njuguna Hilary</b><span class="dot"></span><span>Founder, Afrifama</span><span class="dot"></span><span id="article-date">$dateDisplay</span></div>
</div>
<div class="article-hero">
<img src="$imageDestRelative" alt="$heroAltHtml" loading="eager">
</div>
<article>
$articleHtml
$pdfBlock
</article>
<div class="signature">
<p class="sig-name">This is Afrifama, Diary of an African Entrepreneur</p>
<span class="tagline">Build. Learn. Tell better stories.</span>
</div>
<div class="foot">
<div id="article-nav-bar"></div>
<div class="k">Keep going</div>
<a class="btn" href="founder-notes.html">&larr; All Founder Notes</a>
<div class="links">
<a href="index.html">Home</a>
<a href="https://www.youtube.com/@Afrifama" target="_blank" rel="noopener">YouTube</a>
<a href="https://medium.com/@njugunahilary93" target="_blank" rel="noopener">Medium archive</a>
<a href="mailto:hello@njugunahilary.com">Work with me</a>
</div>
</div>
</div>
<script src="articles.js"></script>
<script>
var THIS_SLUG='$htmlFileName';
var a=getArticleBySlug(THIS_SLUG);
var d=document.getElementById('article-date');
if(a&&d){d.setAttribute('datetime',a.dateISO);d.textContent=a.date;}
renderArticleNav('article-nav-bar',THIS_SLUG);
</script><script src="v14.js"></script></body></html>
"@

Set-Content -LiteralPath $htmlPath -Value $page -Encoding UTF8

$entry = @"
  {
    title: "$(Escape-Js $Title)",
    slug: "$htmlFileName",
    date: "$dateDisplay",
    dateISO: "$dateIso",
    excerpt: "$(Escape-Js $Excerpt)",
    tag: "Founder Notes",
    image: "$imageDestRelative"
  },

"@

$articlesJsPath = Join-Path $repo "articles.js"
$articlesJs = Get-Content -LiteralPath $articlesJsPath -Raw -Encoding UTF8
if ($articlesJs -match [regex]::Escape($htmlFileName)) {
  throw "articles.js already contains $htmlFileName"
}
$articlesMarker = "const ARTICLES = ["
$articlesMarkerIndex = $articlesJs.IndexOf($articlesMarker)
if ($articlesMarkerIndex -lt 0) {
  throw "Could not find the ARTICLES array in articles.js"
}
$articlesJs = $articlesJs.Insert($articlesMarkerIndex + $articlesMarker.Length, "`r`n$entry")
Set-Content -LiteralPath $articlesJsPath -Value $articlesJs -Encoding UTF8

$sitemapPath = Join-Path $repo "sitemap.xml"
if (Test-Path -LiteralPath $sitemapPath) {
  $sitemap = Get-Content -LiteralPath $sitemapPath -Raw -Encoding UTF8
  if ($sitemap -notmatch [regex]::Escape($htmlFileName)) {
    $urlBlock = @"

  <url>
    <loc>https://njugunahilary.com/$htmlFileName</loc>
    <lastmod>$dateIso</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
"@
    $sitemap = $sitemap -replace "\r?\n</urlset>", "$urlBlock`r`n`r`n</urlset>"
    Set-Content -LiteralPath $sitemapPath -Value $sitemap -Encoding UTF8
  }
}

Write-Host ""
Write-Host "Founder Note prepared:" -ForegroundColor Green
Write-Host "  Page:      $htmlFileName"
Write-Host "  Image:     $imageDestRelative"
if ($PdfFile) { Write-Host "  PDF:       $pdfDestRelative" }
Write-Host "  Registry:  articles.js updated"
Write-Host "  Sitemap:   sitemap.xml updated"
Write-Host ""
Write-Host "Preview locally:"
Write-Host "  http://127.0.0.1:8000/$htmlFileName"
Write-Host ""
Write-Host "When approved:"
Write-Host "  git status"
Write-Host "  git add $htmlFileName $imageDestRelative articles.js sitemap.xml$(if ($PdfFile) { " $pdfDestRelative" })"
Write-Host "  git commit -m `"Publish founder note: $Title`""
Write-Host "  git push origin main"

if ($OpenPreview) {
  Start-Process "http://127.0.0.1:8000/$htmlFileName"
}
