param([switch]$Strict)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$errors = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()

function Add-Error([string]$message) { $script:errors.Add($message) }
function Add-Warning([string]$message) { $script:warnings.Add($message) }

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { $nodePath = 'C:\Program Files\nodejs\node.exe'; if (Test-Path $nodePath) { $node = Get-Item $nodePath } }
if (-not $node) { throw "Node.js is required to validate articles.js." }

$articleJson = & $node.Source -e "const fs=require('fs');console.log(eval(fs.readFileSync('articles.js','utf8')+';JSON.stringify(ARTICLES)'))"
if ($LASTEXITCODE -ne 0) { throw "articles.js could not be parsed." }
$articles = $articleJson | ConvertFrom-Json

foreach ($javascript in @('articles.js', 'v14.js')) {
  $null = & $node.Source --check $javascript 2>&1
  if ($LASTEXITCODE -ne 0) { Add-Error "$javascript contains invalid JavaScript." }
}
$sitemap = Get-Content -Raw -Encoding UTF8 sitemap.xml
$previousDate = $null

foreach ($article in $articles) {
  $pagePath = Join-Path $repo $article.slug
  $imagePath = Join-Path $repo $article.image
  if (-not (Test-Path -LiteralPath $pagePath)) { Add-Error "Registry page is missing: $($article.slug)"; continue }
  if (-not (Test-Path -LiteralPath $imagePath)) { Add-Error "Registry image is missing: $($article.image)" }
  if ($sitemap -notmatch [regex]::Escape($article.slug)) { Add-Error "Sitemap is missing: $($article.slug)" }
  if (-not $article.readTime -or $article.readTime -notmatch '^\d+ min read$') { Add-Error "Reading time is missing or invalid: $($article.slug)" }

  $date = [datetime]::ParseExact($article.dateISO, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
  if ($previousDate -and $date -gt $previousDate) { Add-Error "Article registry is not newest-first near $($article.slug)" }
  $previousDate = $date

  $content = Get-Content -Raw -Encoding UTF8 $pagePath
  if ($content -match '<meta name="robots" content="noindex') { Add-Error "$($article.slug) is unexpectedly blocked from indexing." }
  $requirements = @(
    @{ Label='description'; Pattern='<meta name="description" content="[^"]+">' },
    @{ Label='canonical URL'; Pattern='<link rel="canonical" href="https://njugunahilary.com/[^"]+">' },
    @{ Label='Open Graph description'; Pattern='<meta property="og:description" content="[^"]+">' },
    @{ Label='Open Graph image alt'; Pattern='<meta property="og:image:alt" content="[^"]+">' },
    @{ Label='publication date'; Pattern='<meta property="article:published_time" content="\d{4}-\d{2}-\d{2}">' },
    @{ Label='Twitter description'; Pattern='<meta name="twitter:description" content="[^"]+">' },
    @{ Label='Article JSON-LD'; Pattern='<script type="application/ld\+json">[^<]+</script>' },
    @{ Label='semantic visible date'; Pattern='<time id="article-date" datetime="\d{4}-\d{2}-\d{2}">' },
    @{ Label='standard signature'; Pattern='<div class="signature">' },
    @{ Label='article navigation'; Pattern='renderArticleNav\(' }
  )
  foreach ($requirement in $requirements) {
    if ($content -notmatch $requirement.Pattern) { Add-Error "$($article.slug) is missing $($requirement.Label)." }
  }
  foreach ($jsonMatch in [regex]::Matches($content, '<script type="application/ld\+json">([^<]+)</script>')) {
    try { $null = $jsonMatch.Groups[1].Value | ConvertFrom-Json } catch { Add-Error "$($article.slug) contains invalid JSON-LD." }
  }
}

$template = Get-Content -Raw -Encoding UTF8 article-template.html
$requiredTokens = @('TITLE_HTML','DESCRIPTION_HTML','CATEGORY_HTML','HERO_ALT_HTML','DATE_ISO','DATE_DISPLAY','READ_TIME','PAGE_URL','IMAGE_URL','IMAGE_RELATIVE','ARTICLE_HTML','PDF_BLOCK','JSON_LD','SLUG_JS','ORIGINAL_LINK_BLOCK')
foreach ($token in $requiredTokens) { if ($template -notmatch [regex]::Escape("{{$token}}")) { Add-Error "Article template is missing token {{$token}}." } }

$pages = Get-ChildItem -File -Filter '*.html'
foreach ($page in $pages) {
  $content = Get-Content -Raw -Encoding UTF8 $page.FullName
  $ids = [regex]::Matches($content, '\bid="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
  foreach ($duplicate in ($ids | Group-Object | Where-Object Count -gt 1)) { Add-Error "$($page.Name) has duplicate id '$($duplicate.Name)'." }
  foreach ($match in [regex]::Matches($content, '(?:href|src)="([^"#?]+)"')) {
    $reference = $match.Groups[1].Value
    if ($reference -match "['+{}]" -or $reference -match '^(https?:|mailto:|tel:|data:|javascript:)') { continue }
    if ($reference -and -not (Test-Path -LiteralPath (Join-Path $page.DirectoryName $reference))) { Add-Error "$($page.Name) references missing local file '$reference'." }
  }
  if ($page.Name -ne 'article-template.html' -and $content -match '\{\{[A-Z_]+\}\}') { Add-Error "$($page.Name) contains an unresolved publishing token." }
  if ($content -notmatch '<main id="main-content"') { Add-Error "$($page.Name) is missing the main-content landmark." }
  if ($content -notmatch '<a class="skip-link" href="#main-content">') { Add-Error "$($page.Name) is missing the skip link." }

  $inlineIndex = 0
  $inlinePattern = '<script(?![^>]*type="application/ld\+json")(?![^>]*src=)[^>]*>([\s\S]*?)</script>'
  foreach ($scriptMatch in [regex]::Matches($content, $inlinePattern)) {
    $javascript = $scriptMatch.Groups[1].Value
    if (-not $javascript.Trim()) { continue }
    $tempScript = Join-Path ([IO.Path]::GetTempPath()) ("nh-site-check-{0}-{1}.js" -f $PID, $inlineIndex)
    try {
      Set-Content -LiteralPath $tempScript -Value $javascript -Encoding UTF8
      $null = & $node.Source --check $tempScript 2>&1
      if ($LASTEXITCODE -ne 0) { Add-Error "$($page.Name) contains invalid inline JavaScript (block $inlineIndex)." }
    }
    finally { if (Test-Path -LiteralPath $tempScript) { Remove-Item -LiteralPath $tempScript -Force } }
    $inlineIndex++
  }
}

try { $null = [xml](Get-Content -Raw -Encoding UTF8 sitemap.xml) } catch { Add-Error "sitemap.xml is not valid XML." }

if ($Strict) {
  foreach ($page in $pages) {
    $content = Get-Content -Raw -Encoding UTF8 $page.FullName
    foreach ($img in [regex]::Matches($content, '<img\b[^>]*>')) {
      if ($img.Value -notmatch '\balt=') { Add-Error "$($page.Name) has an image without alt text." }
    }
  }
}

foreach ($warning in $warnings) { Write-Warning $warning }
if ($errors.Count) {
  $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
  Write-Host "Validation failed with $($errors.Count) error(s)." -ForegroundColor Red
  exit 1
}
Write-Host "Validation passed: $($articles.Count) Founder Notes and $($pages.Count) HTML pages checked." -ForegroundColor Green
