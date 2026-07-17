param(
  [Parameter(Mandatory=$true)][string]$Title,
  [string]$Date = (Get-Date).ToString("yyyy-MM-dd"),
  [Parameter(Mandatory=$true)][string]$Excerpt,
  [Parameter(Mandatory=$true)][string]$ArticleFile,
  [Parameter(Mandatory=$true)][string]$ImageFile,
  [string]$PdfFile = "",
  [string]$OriginalUrl = "",
  [string]$Category = "",
  [string]$HeroAlt = "",
  [string]$Slug = "",
  [switch]$OpenPreview,
  [switch]$ValidateOnly
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
  $s = $value.ToLowerInvariant() -replace "&", " and " -replace "[^a-z0-9]+", "-"
  $s = $s.Trim("-")
  if (-not $s) { throw "Could not create a slug from the title." }
  return "founder-notes-$s"
}

function Escape-Html([string]$value) { return [System.Net.WebUtility]::HtmlEncode($value) }
function Escape-Js([string]$value) { return ($value -replace "\\", "\\\\" -replace '"', '\"' -replace "`r?`n", " ") }
function Convert-ToDisplayDate([datetime]$value) { return $value.ToString("MMMM d, yyyy", [Globalization.CultureInfo]::InvariantCulture) }
function Convert-ToIsoDate([datetime]$value) { return $value.ToString("yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture) }

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
    if ($LASTEXITCODE -eq 0 -and ($output -join "`n").Trim()) { return ($output -join "`n") }
  }
  throw "Could not extract text from this PDF. Paste the article into incoming-articles/article.txt and pass the PDF separately with -PdfFile."
}

function Convert-ArticleTextToHtml([string]$text) {
  $blocks = [regex]::Split($text.Trim(), "(?:\r?\n){2,}") | Where-Object { $_.Trim() }
  $html = [Collections.Generic.List[string]]::new()
  $plainText = [Collections.Generic.List[string]]::new()
  $paragraphNumber = 0

  foreach ($raw in $blocks) {
    $block = $raw.Trim()
    if ($block -match "^-{3,}$") { $html.Add('<hr class="divider">'); continue }
    if ($block -match "^#\s+") { continue }
    if ($block -match "^##\s+(.+)$") {
      $value = $Matches[1].Trim(); $html.Add("<h2>$(Escape-Html $value)</h2>"); $plainText.Add($value); continue
    }
    if ($block -match "^>\s*(.+)$") {
      $value = ($block -replace "^>\s*", "" -replace "\r?\n", " ").Trim()
      $html.Add("<p class=`"pull`">$(Escape-Html $value)</p>"); $plainText.Add($value); continue
    }
    $lines = $block -split "\r?\n"
    if (($lines | Where-Object { $_ -notmatch "^\s*[-*]\s+" }).Count -eq 0) {
      $items = $lines | ForEach-Object { ($_ -replace "^\s*[-*]\s+", "").Trim() }
      $html.Add("<ul>`r`n$($items | ForEach-Object { '<li>' + (Escape-Html $_) + '</li>' } | Out-String)</ul>")
      foreach ($item in $items) { $plainText.Add($item) }
      continue
    }
    $paragraphNumber++
    $value = ($block -replace "\r?\n", " ").Trim()
    $class = if ($paragraphNumber -eq 1) { ' class="lead"' } else { "" }
    $html.Add("<p$class>$(Escape-Html $value)</p>")
    $plainText.Add($value)
  }

  if ($html.Count -eq 0) { throw "The article file did not contain publishable text." }
  $wordCount = ([regex]::Matches(($plainText -join " "), "\b[\p{L}\p{N}'’-]+\b")).Count
  $readMinutes = [Math]::Max(1, [Math]::Ceiling($wordCount / 220))
  return @{ Html = ($html -join "`r`n`r`n"); WordCount = $wordCount; ReadTime = "$readMinutes min read" }
}

function Convert-CoverImage([string]$source, [string]$destinationBase) {
  $extension = [IO.Path]::GetExtension($source).ToLowerInvariant()
  if ($extension -notin @(".jpg", ".jpeg", ".png", ".webp")) { throw "Image must be JPG, PNG, or WebP." }
  $webpDestination = "$destinationBase.webp"
  if ($extension -eq ".webp") { Copy-Item -LiteralPath $source -Destination $webpDestination; return $webpDestination }

  $cwebp = Get-CommandPath @("cwebp")
  if ($cwebp) {
    & $cwebp -quiet -q 82 -m 6 $source -o $webpDestination
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $webpDestination)) { return $webpDestination }
  }
  $magick = Get-CommandPath @("magick")
  if ($magick) {
    & $magick $source -auto-orient -strip -quality 82 $webpDestination
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $webpDestination)) { return $webpDestination }
  }
  throw "A WebP converter is required for JPG/PNG covers. Install cwebp or ImageMagick, or provide a .webp image."
}

function Replace-Token([string]$template, [string]$name, [string]$value) {
  return $template.Replace("{{$name}}", $value)
}

$repo = Resolve-RepoRoot
Set-Location -LiteralPath $repo
$templatePath = Join-Path $repo "article-template.html"
$articlesPath = Join-Path $repo "articles.js"
$sitemapPath = Join-Path $repo "sitemap.xml"
foreach ($required in @($templatePath, $articlesPath, $sitemapPath)) {
  if (-not (Test-Path -LiteralPath $required)) { throw "Required publishing file is missing: $required" }
}

$articlePath = (Resolve-Path -LiteralPath $ArticleFile).Path
$imagePath = (Resolve-Path -LiteralPath $ImageFile).Path
$articleExtension = [IO.Path]::GetExtension($articlePath).ToLowerInvariant()
if ($articleExtension -notin @(".txt", ".md", ".pdf")) { throw "ArticleFile must be TXT, Markdown, or PDF." }
if ($OriginalUrl -and -not [Uri]::IsWellFormedUriString($OriginalUrl, [UriKind]::Absolute)) { throw "OriginalUrl must be a complete URL." }

$dateValue = [datetime]::ParseExact($Date, "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
$dateDisplay = Convert-ToDisplayDate $dateValue
$dateIso = Convert-ToIsoDate $dateValue
if (-not $Category) {
  $Category = if ($Title -match '^What Keeps Me Up at Night(?:\s*:|$)') {
    "What Keeps Me Up At Night"
  } else {
    "Diary of an African Entrepreneur"
  }
}
if (-not $Slug) { $Slug = Convert-ToSlug $Title }
if ($Slug -notmatch "^founder-notes-[a-z0-9-]+$") { throw "Slug must start with founder-notes- and contain lowercase letters, numbers, and hyphens only." }

$htmlFileName = "$Slug.html"
$htmlPath = Join-Path $repo $htmlFileName
if (Test-Path -LiteralPath $htmlPath) { throw "$htmlFileName already exists." }
$articles = Get-Content -Raw -Encoding UTF8 $articlesPath
if ($articles -match [regex]::Escape($htmlFileName)) { throw "articles.js already contains $htmlFileName." }

$rawArticle = if ($articleExtension -eq ".pdf") { Convert-PdfToText $articlePath } else { Get-Content -Raw -Encoding UTF8 $articlePath }
$converted = Convert-ArticleTextToHtml $rawArticle
if (-not $HeroAlt) { $HeroAlt = $Title }

$stage = Join-Path $repo (".publish-staging-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stage | Out-Null
try {
  $imageStaged = Convert-CoverImage $imagePath (Join-Path $stage $Slug)
  $imageFileName = [IO.Path]::GetFileName($imageStaged)
  $imageRelative = "images/$imageFileName"
  $pageUrl = "https://njugunahilary.com/$htmlFileName"
  $imageUrl = "https://njugunahilary.com/$imageRelative"

  $pdfBlock = ""; $pdfRelative = ""; $pdfStaged = ""
  if ($articleExtension -eq ".pdf" -and -not $PdfFile) { $PdfFile = $articlePath }
  if ($PdfFile) {
    $resolvedPdf = (Resolve-Path -LiteralPath $PdfFile).Path
    if ([IO.Path]::GetExtension($resolvedPdf).ToLowerInvariant() -ne ".pdf") { throw "PdfFile must be a PDF." }
    $pdfRelative = "files/$Slug.pdf"; $pdfStaged = Join-Path $stage "$Slug.pdf"
    Copy-Item -LiteralPath $resolvedPdf -Destination $pdfStaged
    $pdfBlock = "<p><a class=`"pdf-link`" href=`"$pdfRelative`" target=`"_blank`" rel=`"noopener`">Read or download the original PDF &rarr;</a></p>"
  }

  $originalLinkBlock = if ($OriginalUrl) { "<a href=`"$(Escape-Html $OriginalUrl)`" target=`"_blank`" rel=`"noopener`">Original publication</a>" } else { '<a href="https://medium.com/@njugunahilary93" target="_blank" rel="noopener">Medium archive</a>' }
  $jsonLd = @{ '@context'='https://schema.org'; '@type'='Article'; headline=$Title; description=$Excerpt; datePublished=$dateIso; dateModified=$dateIso; mainEntityOfPage=$pageUrl; image=$imageUrl; wordCount=$converted.WordCount; timeRequired="PT$($converted.ReadTime.Split(' ')[0])M"; author=@{ '@type'='Person'; name='Njuguna Hilary'; url='https://njugunahilary.com/' }; publisher=@{ '@type'='Person'; name='Njuguna Hilary'; url='https://njugunahilary.com/' } } | ConvertTo-Json -Compress -Depth 5

  $page = Get-Content -Raw -Encoding UTF8 $templatePath
  $page = $page.Replace('<meta name="robots" content="noindex,nofollow">', '')
  $tokens = @{
    TITLE_HTML=(Escape-Html $Title); DESCRIPTION_HTML=(Escape-Html $Excerpt); CATEGORY_HTML=(Escape-Html $Category)
    HERO_ALT_HTML=(Escape-Html $HeroAlt); DATE_ISO=$dateIso; DATE_DISPLAY=$dateDisplay; READ_TIME=$converted.ReadTime
    PAGE_URL=$pageUrl; IMAGE_URL=$imageUrl; IMAGE_RELATIVE=$imageRelative; ARTICLE_HTML=$converted.Html
    PDF_BLOCK=$pdfBlock; JSON_LD=$jsonLd; SLUG_JS=(Escape-Js $htmlFileName); ORIGINAL_LINK_BLOCK=$originalLinkBlock
  }
  foreach ($token in $tokens.Keys) { $page = Replace-Token $page $token ([string]$tokens[$token]) }
  if ($page -match "\{\{[A-Z_]+\}\}") { throw "The article template contains an unresolved token: $($Matches[0])" }
  if ($page -match '<meta name="robots" content="noindex') { throw "Generated article unexpectedly contains a noindex directive." }

  $entry = @"
  {
    title: "$(Escape-Js $Title)",
    slug: "$htmlFileName",
    date: "$dateDisplay",
    dateISO: "$dateIso",
    excerpt: "$(Escape-Js $Excerpt)",
    tag: "Founder Notes",
    image: "$imageRelative",
    readTime: "$($converted.ReadTime)"
  },

"@
  $marker = "const ARTICLES = ["
  $markerIndex = $articles.IndexOf($marker)
  if ($markerIndex -lt 0) { throw "Could not find the ARTICLES array." }
  $updatedArticles = $articles.Insert($markerIndex + $marker.Length, "`r`n$entry")

  $sitemap = Get-Content -Raw -Encoding UTF8 $sitemapPath
  $urlBlock = "  <url><loc>$pageUrl</loc><lastmod>$dateIso</lastmod><priority>0.8</priority></url>"
  $updatedSitemap = $sitemap -replace "\r?\n</urlset>", "`r`n$urlBlock`r`n</urlset>"
  $updatedSitemap = [regex]::Replace(
    $updatedSitemap,
    '(<loc>https://njugunahilary.com/</loc>\s*<lastmod>)[^<]+',
    { param($match) $match.Groups[1].Value + $dateIso }
  )
  $updatedSitemap = [regex]::Replace(
    $updatedSitemap,
    '(<loc>https://njugunahilary.com/founder-notes.html</loc>\s*<lastmod>)[^<]+',
    { param($match) $match.Groups[1].Value + $dateIso }
  )

  $utf8NoBom = New-Object Text.UTF8Encoding($false)
  [IO.File]::WriteAllText((Join-Path $stage $htmlFileName), $page.TrimEnd() + [Environment]::NewLine, $utf8NoBom)
  [IO.File]::WriteAllText((Join-Path $stage "articles.js"), $updatedArticles.TrimEnd() + [Environment]::NewLine, $utf8NoBom)
  [IO.File]::WriteAllText((Join-Path $stage "sitemap.xml"), $updatedSitemap.TrimEnd() + [Environment]::NewLine, $utf8NoBom)

  Write-Host "Validated: $Title ($($converted.WordCount) words, $($converted.ReadTime))" -ForegroundColor Green
  if ($ValidateOnly) { Write-Host "No website files were changed."; return }

  $destinations = @($htmlPath, (Join-Path $repo $imageRelative), $articlesPath, $sitemapPath)
  if ($pdfRelative) { $destinations += (Join-Path $repo $pdfRelative) }
  foreach ($destination in $destinations) {
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
  }
  Move-Item -LiteralPath (Join-Path $stage $htmlFileName) -Destination $htmlPath
  Move-Item -LiteralPath $imageStaged -Destination (Join-Path $repo $imageRelative)
  Move-Item -LiteralPath (Join-Path $stage "articles.js") -Destination $articlesPath -Force
  Move-Item -LiteralPath (Join-Path $stage "sitemap.xml") -Destination $sitemapPath -Force
  if ($pdfRelative) { Move-Item -LiteralPath $pdfStaged -Destination (Join-Path $repo $pdfRelative) }

  Write-Host "Founder Note prepared: $htmlFileName" -ForegroundColor Green
  Write-Host "Preview: file:///$($htmlPath -replace '\\','/')"
  if ($OpenPreview) { Start-Process "file:///$($htmlPath -replace '\\','/')" }
}
finally {
  if (Test-Path -LiteralPath $stage) {
    $resolvedStage = (Resolve-Path -LiteralPath $stage).Path
    $allowedPrefix = (Join-Path $repo '.publish-staging-')
    if (-not $resolvedStage.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove an unexpected staging path: $resolvedStage"
    }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
  }
}
