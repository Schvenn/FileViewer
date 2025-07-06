function fileviewer ($file, [string[]]$filearray, [switch]$documents, [string]$search, [switch]$help) {# File Viewer.
$script:file = $file; $script:filearray = $filearray; $pattern = "(?i)$search"; ""; $searchHits = @(); $content = @()

# Accept search terms, if passed.
if ($search) {$searchTerm = "$search"}

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

if ($help) {# Inline help.
function scripthelp ($section) {# (Internal) Generate the help sections from the comments section of the script.
""; Write-Host -f yellow ("-" * 100); $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; Write-Host -f yellow ("-" * 100)
if ($lines.Count -gt 1) {wordwrap $lines[1] 100| Out-String | Out-Host -Paging}; Write-Host -f yellow ("-" * 100)}
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}

$selection = $null
do {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help Sections:`n" -f cyan; for ($i = 0; $i -lt $sections.Count; $i++) {
"{0}: {1}" -f ($i + 1), $sections[$i].Groups[1].Value}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
$input = Read-Host "`nEnter a section number to view"
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

# File array selection menu
function filemenu_virtual ($script:filearray) {$page = 0; $perpage = 30; $script:file = $null; $errormessage = $null
while ($true) {cls; $input = $null; $entryIndex = $null; $sel = $null
Write-Host -f cyan "Search Results (Page $($page + 1))`n"; $startIndex = $page * $perpage; $endIndex = [Math]::Min(($page + 1) * $perpage - 1, $script:filearray.Count - 1); $paged = $script:filearray[$startIndex..$endIndex]; $optionCount = 0
for ($i = 0; $i -lt $paged.Count; $i++) {$optionCount++; $name = Split-Path -Leaf $paged[$i]; Write-Host -f white "$optionCount. $name" -n; $sizeKB = try {[math]::Round(((Get-Item $paged[$i]).Length + 500) / 1KB, 0)} catch {" "}; Write-Host -f white " [$sizeKB KB]"}
if (($page + 1) * $perpage -lt $script:filearray.Count) {$optionCount++; Write-Host "$optionCount. NEXT..." -f Cyan}
Write-Host -f red "`n$errormessage"; Write-Host -f White "Make a selection or press Enter" -n; $input = Read-Host " "
if (-not $input) {return}
if ($input -match '^\d+$') {$sel = [int]$input; $entryIndex = $sel - 1
if ($entryIndex -ge 0 -and $entryIndex -lt $paged.Count) {$script:file = $paged[$entryIndex]; return}
elseif ($sel -eq $optionCount -and ($page + 1) * $perpage -lt $script:filearray.Count) {$page++} else {$errormessage = "Invalid selection."}}
else {$errormessage = "Invalid input."}}}

if ($script:filearray -and -not $script:file) {filemenu_virtual $script:filearray}

# File selection menu.
function filemenu {param([string]$path, [string]$parentPath = $null)
if (-not $path) {$path = (Get-Location)}
$page = 0; $perpage = 30; $script:file = $null; $errormessage = $null
while ($true) {cls; Write-Host -f cyan "Select a file to view from: " -n; Write-Host -f white "$path`n"
if ($documents) {$filepattern = '(?i)\.(1st|backup|bat|cmd|doc|gz(ip)?|htm?l|log|me|ps[dm]?1|te?mp)$'} else {$filepattern = '.+'}
$dirs = Get-ChildItem -LiteralPath $path -Directory -Force | Sort-Object Name; $script:files = Get-ChildItem -LiteralPath $path -File -Force | Where-Object {$_.Extension -match $filepattern} | Sort-Object Name; $entries = @(@($dirs) + @($script:files))
if ($entries.Count -eq 0) {Write-Host -f yellow ".."; Write-Host -f red "No viewable files found."; Write-Host -f white "`nPress Enter to return to previous menu." -n; [void] (Read-Host); return}
$startIndex = $page * $perpage; $endIndex = [Math]::Min(($page + 1) * $perpage - 1, $entries.Count - 1); $paged = $entries[$startIndex..$endIndex]; $optionCount = 0
if ($parentPath) {$optionCount++; Write-Host -f yellow "$optionCount. .."}
for ($i = 0; $i -lt $paged.Count; $i++) {$optionCount++; $item = $paged[$i]; $colour = if ($item.PSIsContainer) {'Yellow'} else {'White'}; $sizeKB = try {[math]::Round([math]::Max(((Get-Item $paged[$i]).Length + 500) / 1KB, 0.5), 0)} catch {" "}
if ($sizeKB -gt 0) {Write-Host -f $colour "$optionCount. $($item.Name)" -n; Write-Host -f white " [$sizeKB KB]"}
else {Write-Host -f $colour "$optionCount. $($item.Name)"}}
if (($page + 1) * $perpage -lt $entries.Count) {$optionCount++; Write-Host "$optionCount. NEXT..." -f Cyan}
Write-Host -f red "`n$errormessage"
Write-Host -f White "Make a selection or press Enter" -n; $input = Read-Host " "
if (-not $input) {return}
if ($input -match '^\d+$') {$sel = [int]$input
if ($parentPath -and $sel -eq 1) {return}

# Adjust selection index if ".." present
$entryIndex = if ($parentPath) {$sel - 2} else {$sel - 1}
if ($entryIndex -ge 0 -and $entryIndex -lt $paged.Count) {$selected = $paged[$entryIndex]
if ($selected.PSIsContainer) {filemenu $selected.FullName $path
if ($script:file) {return}}
else {$script:file = $selected.FullName; return}}
elseif ($sel -eq $optionCount -and ($page + 1) * $perpage -lt $entries.Count) {$page++}
else {$errormessage = "Invalid selection."}}
else {$errormessage = "Invalid input."}}}

# Run selection menu if a directory path was passed to the script, rather than a file.
if ((Test-Path $script:file -PathType Container -ea SilentlyContinue) -or (-not $script:file -and -not $script:filearray)) {filemenu $script:file}

# Error-checking
if (-not (Test-Path $script:file -PathType Leaf -ea SilentlyContinue) -or (-not $script:file)) {Write-Host -f red "`nNo file provided.`n"; return}
if (-not (Test-Path $script:file)) {Write-Host -f red "`nFile not found.`n"; return}

# Read GZip files.
if ($script:file -like "*.gz") {try {$stream = [System.IO.File]::OpenRead($script:file); $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Decompress); $reader = New-Object System.IO.StreamReader($gzip); $rawText = $reader.ReadToEnd(); $reader.Close(); $gzip.Close(); $stream.Close(); $content = $rawText -split "`r?`n"}
catch {Write-Host -f red "`nFailed to read compressed file: $script:file`n"; return}}

# Read plaintext files.
else {$content = Get-Content $script:file}

if (-not $content) {Write-Host -f red "`nFile is empty.`n"; return}

$searchHits = @(0..($content.Count - 1) | Where-Object {$content[$_] -match $pattern}); $currentSearchIndex = $searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1; $pos = $currentSearchIndex

$content = $content | ForEach-Object {wordwrap $_ $null} | ForEach-Object {$_ -split "`n"}

$pageSize = 44; $pos = 0; $script:fileName = [System.IO.Path]::GetFileName($script:file); $searchHits = @(); $currentSearchIndex = -1

function getbreakpoint {param($start); return [Math]::Min($start + $pageSize - 1, $content.Count - 1)}

function showpage {cls; $start = $pos; $end = getbreakpoint $start; $pageLines = $content[$start..$end]; $highlight = if ($searchTerm) {"$pattern"} else {$null}
foreach ($line in $pageLines) {if ($highlight -and $line -match $highlight) {$parts = [regex]::Split($line, "($highlight)")
foreach ($part in $parts) {if ($part -match "^$highlight$") {Write-Host -f black -b yellow $part -n}
else {Write-Host -f white $part -n}}; ""}
else {Write-Host -f white $line}}

# Pad with blank lines if this page has fewer than $pageSize lines
$linesShown = $end - $start + 1
if ($linesShown -lt $pageSize) {for ($i = 1; $i -le ($pageSize - $linesShown); $i++) {Write-Host ""}}}

# Main menu loop
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"
while ($true) {showpage; $pageNum = [math]::Floor($pos / $pageSize) + 1; $totalPages = [math]::Ceiling($content.Count / $pageSize)
if ($searchHits.Count -gt 0) {$currentMatch = [array]::IndexOf($searchHits, $pos); if ($currentMatch -ge 0) {$searchmessage = "Match $($currentMatch + 1) of $($searchHits.Count)"}
else {$searchmessage = "Search active ($($searchHits.Count) matches)"}}

line yellow -double
if (-not $errormessage -or $errormessage.length -lt 1) {$middlecolour = "white"; $middle = $statusmessage} else {$middlecolour = "red"; $middle = $errormessage}
$left = "$script:fileName".PadRight(57); $middle = "$middle".PadRight(44); $right = "(Page $pageNum of $totalPages)"
Write-Host -f white $left -n; Write-Host -f $middlecolour $middle -n; Write-Host -f cyan $right
$left = "Page Commands".PadRight(55); $middle = "| $searchmessage ".PadRight(34); $right = "| Exit Commands"
Write-Host -f yellow ($left + $middle + $right)
Write-Host -f yellow "[F]irst [N]ext [+/-]# Lines P[A]ge # [P]revious [L]ast | [<][S]earch[>] [#]Match [C]lear | [D]ump [X]Edit [M]enu [Q]uit " -n
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"

function getaction {[string]$buffer = ""
while ($true) {$key = [System.Console]::ReadKey($true)
switch ($key.Key) {'LeftArrow' {return 'P'}
'UpArrow' {return 'U1L'}
'Backspace' {return 'P'}
'PageUp' {return 'P'}
'RightArrow' {return 'N'}
'DownArrow' {return 'D1L'}
'PageDown' {return 'N'}
'Enter' {if ($buffer) {return $buffer}
else {return 'N'}}
'Home' {return 'F'}
'End' {return 'L'}
default {$char = $key.KeyChar
switch ($char) {',' {return '<'}
'.' {return '>'}
{$_ -match '(?i)[B-Z]'} {return $char.ToString().ToUpper()}
{$_ -match '[A#\+\-\d]'} {$buffer += $char}
default {$buffer = ""}}}}}}

$action = getaction

switch ($action.ToString().ToUpper()) {'F' {$pos = 0}
'N' {$next = getbreakpoint $pos; if ($next -lt $content.Count - 1) {$pos = $next + 1}
else {$pos = [Math]::Min($pos + $pageSize, $content.Count - 1)}}
'P' {$pos = [Math]::Max(0, $pos - $pageSize)}
'L' {$lastPageStart = [Math]::Max(0, [int][Math]::Floor(($content.Count - 1) / $pageSize) * $pageSize); $pos = $lastPageStart}

'<' {$currentSearchIndex = ($searchHits | Where-Object {$_ -lt $pos} | Select-Object -Last 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[-1]; $statusmessage = "Wrapped to last match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'S' {Write-Host -f green "`n`nKeyword to search forward from this point in the logs" -n; $searchTerm = Read-Host " "
if (-not $searchTerm) {$errormessage = "No keyword entered."; $statusmessage = $null; $searchTerm = $null; $searchHits = @(); continue}
$pattern = "(?i)$searchTerm"; $searchHits = @(0..($content.Count - 1) | Where-Object { $content[$_] -match $pattern })
if ($searchHits.Count -eq 0) {$errormessage = "Keyword not found in file."; $statusmessage = $null; $currentSearchIndex = -1}
else {$currentSearchIndex = $searchHits | Where-Object { $_ -gt $pos } | Select-Object -First 1
if ($null -eq $currentSearchIndex) {Write-Host -f green "No match found after this point. Jump to first match? (Y/N)" -n; $wrap = Read-Host " "
if ($wrap -match '^[Yy]$') {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
else {$errormessage = "Keyword not found further forward."; $statusmessage = $null; $searchHits = @(); $searchTerm = $null}}
$pos = $currentSearchIndex}}
'>' {$currentSearchIndex = ($searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'C' {$searchTerm = $null; $searchHits.Count = 0; $searchHits = @(); $currentSearchIndex = $null}

'D' {""; gc $script:file | more; return}
'X' {edit $script:file; "" ; return}
'M' {if ($script:filearray) {fileviewer -filearray $script:filearray; return} else {return fileviewer (Get-Location)}}
'Q' {"`n"; return}
'U1L' {$pos = [Math]::Max($pos - 1, 0)}
'D1L' {$pos = [Math]::Min($pos + 1, $content.Count - $pageSize)}

default {if ($action -match '^[\+\-](\d+)$') {$offset = [int]$action; $newPos = $pos + $offset; $pos = [Math]::Max(0, [Math]::Min($newPos, $content.Count - $pageSize))}

elseif ($action -match '^(\d+)$') {$jump = [int]$matches[1]
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null; continue}
$targetIndex = $jump - 1
if ($targetIndex -ge 0 -and $targetIndex -lt $searchHits.Count) {$pos = $searchHits[$targetIndex]
if ($targetIndex -eq 0) {$statusmessage = "Jumped to first match."}
else {$statusmessage = "Jumped to match #$($targetIndex + 1)."}; $errormessage = $null}
else {$errormessage = "Match #$jump is out of range."; $statusmessage = $null}}

elseif ($action -match '^A(\d+)$') {$requestedPage = [int]$matches[1]
if ($requestedPage -lt 1 -or $requestedPage -gt $totalPages) {$errormessage = "Page #$requestedPage is out of range."; $statusmessage = $null}
else {$pos = ($requestedPage - 1) * $pageSize}}

else {$errormessage = "Invalid input."; $statusmessage = $null}}}}}

Export-ModuleMember -Function fileviewer

<#
## fileviewer
This file viewer will present files on screen for easy viewing.

Usage: fileviewer <filename> <filearray> <search> -documents -help

• If no file is provided, a file selection menu is presented.
• If a file array is provided, the file selection menu is presented, populated with those files.
• Search terms can be passed to the file viewer right from the command line, which is especially useful for the filearray option.
• Use the -documents switch to limit files within the selector to the following extensions: 1st, backup, bat, cmd, doc, htm, html, log, me, ps1, psd1, psm1, temp, temp.

Once inside the viewer, the options include:

Navigation:

Navigation:

[F]irst page / [HOME]
[N]ext page / [PgDn] / [Right]
[+/-]# to move forward or back a specific # of lines / [Down] / [Up]
p[A]ge # to jump to a specific page
[P]revious page / [PgUp] / [Left]
[L]ast page / [END]

Search:

[S]earch for a term
[<] Previous match
[>] Next match
[#]Number to find a specific match number
[C]lear search term

Exit Commands:

[D]ump to screen with | MORE and Exit
[X]Edit using Notepad++, if available. Otherwise, use Notepad.
[M]enu to open the file selection menu
[Q]uit
##>
