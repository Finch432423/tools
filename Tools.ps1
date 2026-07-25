# =======================
# TOOLS COLLECTOR
# =======================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Box-drawing via codepoints so the script parses even if the file is not UTF-8 with BOM
$U = @{
    H  = [string][char]0x2500  # ─
    HD = [string][char]0x2550  # ═
    V  = [string][char]0x2502  # │
    TL = [string][char]0x250C  # ┌
    TR = [string][char]0x2510  # ┐
    BL = [string][char]0x2514  # └
    BR = [string][char]0x2518  # ┘
    ARR = [string][char]0x2192  # →
}

# Enable VT processing on legacy consoles when possible (improves colors in some hosts)
if ($Host.UI.SupportsVirtualTerminal -eq $false -and $PSVersionTable.PSVersion.Major -lt 7) {
    try {
        $sig = @'
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, uint m);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int n);
'@
        $t = Add-Type -MemberDefinition $sig -Name ConsoleMode -Namespace Win32 -PassThru
        $h = $t::GetStdHandle(-11)
        [uint32]$m = 0
        if ($t::GetConsoleMode($h, [ref]$m)) { [void]$t::SetConsoleMode($h, $m -bor 4) }
    } catch { }
}

function Get-TermWidth {
    try {
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -gt 0) { return [Math]::Max(48, [Math]::Min(80, $w - 2)) }
    } catch { }
    return 72
}

function Write-TermRule {
    param([string]$Char, [ConsoleColor]$Color = "DarkGray")
    if (-not $Char) { $Char = $U.H }
    $len = Get-TermWidth
    Write-Host ($Char * $len) -ForegroundColor $Color
}

function Write-TermHeader {
    $title = "TOOLS COLLECTOR"
    $credit = "ui + tools"
    $w = Get-TermWidth
    $inner = $w - 2
    Write-Host ""
    Write-Host ($U.TL + ($U.H * $inner) + $U.TR) -ForegroundColor DarkGray
    $pad = [Math]::Max(0, [Math]::Floor(($inner - $title.Length) / 2))
    Write-Host ($U.V + (" " * $pad) + $title + (" " * ($inner - $pad - $title.Length)) + $U.V) -ForegroundColor Cyan
    Write-Host ($U.V + (" " * $inner) + $U.V) -ForegroundColor DarkGray
    if ($credit.Length -gt $inner) {
        $credit = $credit.Substring(0, [Math]::Max(0, $inner - 3)) + "..."
    }
    $cp = [Math]::Max(0, [Math]::Floor(($inner - $credit.Length) / 2))
    Write-Host ($U.V + (" " * $cp) + $credit + (" " * ($inner - $cp - $credit.Length)) + $U.V) -ForegroundColor DarkGray
    Write-Host ($U.BL + ($U.H * $inner) + $U.BR) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-TermSection {
    param([string]$Label)
    Write-Host ""
    Write-TermRule -Char $U.H -Color DarkGray
    Write-Host "  $Label" -ForegroundColor Cyan
    Write-TermRule -Char $U.H -Color DarkGray
}

cls
Write-TermHeader


if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "  > elevation required - relaunching as administrator..." -ForegroundColor Yellow
    Start-Proce powershell -Verb RunAs -ArgumentList `
        "-ExecutionPolicy Bypa -File `"$($MyInvocation.MyCommand.Definition)`""
    exit 0
}


$root = "C:\"
$name = "Screenshare"
$i = 1
while (Test-Path "$root$name$i") { $i++ }
$folder = "$root$name$i"

New-Item -Path $folder -ItemType Directory -Force | Out-Null
Set-Location $folder
Write-TermSection "workspace"
Write-Host "  " -NoNewline
Write-Host "[OK]" -ForegroundColor Green -NoNewline
Write-Host " " -NoNewline
Write-Host $folder -ForegroundColor DarkCyan


function Add-DefenderExclusion {
    Write-TermSection "windows defender"
    Write-Host "  " -NoNewline
    Write-Host "[..]" -ForegroundColor DarkCyan -NoNewline
    Write-Host " adding exclusion path..." -ForegroundColor DarkGray
    try {
        if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
            $prefs = (Get-MpPreference).ExclusionPath
            if ($prefs -notcontains $folder) {
                Add-MpPreference -ExclusionPath $folder
                Write-Host "  " -NoNewline
                Write-Host "[OK]" -ForegroundColor Green -NoNewline
                Write-Host " exclusion registered (Defender)" -ForegroundColor Gray
            } else {
                Write-Host "  " -NoNewline
                Write-Host "[..]" -ForegroundColor DarkGray -NoNewline
                Write-Host " path already excluded" -ForegroundColor DarkGray
            }
            return
        }
    } catch { }

    try {
        $reg = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
        if (Test-Path $reg) {
            New-ItemProperty -Path $reg -Name $folder -Value 0 -PropertyType DWORD -Force | Out-Null
            Write-Host "  " -NoNewline
            Write-Host "[OK]" -ForegroundColor Green -NoNewline
            Write-Host " exclusion registered (registry)" -ForegroundColor Gray
            return
        }
    } catch { }

    Write-Host "  " -NoNewline
    Write-Host "[!!]" -ForegroundColor Yellow -NoNewline
    Write-Host " could not add exclusion" -ForegroundColor DarkYellow
}
Add-DefenderExclusion


Add-Type -AssemblyName System.IO.Compression.FileSystem


function Download-File {
    param ([string]$Url)

    $fileName = Split-Path $Url -Leaf
    $dest = Join-Path $folder $fileName

    try {
        Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing
        Write-Host "      " -NoNewline
        Write-Host "done" -ForegroundColor Green -NoNewline
        Write-Host "  " -NoNewline
        Write-Host $fileName -ForegroundColor Gray

        if ($fileName.ToLower().EndsWith(".zip")) {
            $outDir = Join-Path $folder ([IO.Path]::GetFileNameWithoutExtension($fileName))
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($dest, $outDir, $true)
            Remove-Item $dest -Force
            Write-Host "      " -NoNewline
            Write-Host "extract" -ForegroundColor DarkCyan -NoNewline
            Write-Host (" " + $U.ARR + " ") -NoNewline -ForegroundColor DarkGray
            Write-Host $outDir -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "      " -NoNewline
        Write-Host "fail" -ForegroundColor Red -NoNewline
        Write-Host "  " -NoNewline
        Write-Host $fileName -ForegroundColor DarkRed
    }
}

# -----------------------
# URLs
# -----------------------
$urls = @(
    'https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe',
    'https://github.com/spokwn/Tool/releases/download/v1.1.3/espouken.exe',
    'https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe',
    'https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe',
    'https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe',
    'https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTrace.exe',
    'https://www.nirsoft.net/utils/winprefetchview-x64.zip',
    'https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe',
    'https://www.nirsoft.net/utils/usbdeview-x64.zip',
    'https://www.nirsoft.net/utils/networkusageview-x64.zip',
    'https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip',
    'https://www.nirsoft.net/utils/usbdrivelog.zip',
    'https://www.nirsoft.net/utils/previousfilesrecovery-x64.zip',
    'https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe',
    'https://github.com/zedoonvm1/TasksParser/releases/download/1.1/Tasks.Parser.exe',
    'https://github.com/Orbdiff/Fileless/releases/download/v1.1/Fileless.exe',
    'https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe',
    'https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.3/PrefetchView++.exe'
    )


$counter = 0
$total = $urls.Count

Write-TermSection "downloads ($total packages)"
foreach ($url in $urls) {
    $counter++
    $leaf = Split-Path $url -Leaf
    $pct = if ($total -gt 0) { [int](($counter / $total) * 100) } else { 0 }
    Write-Progress -Activity "Tools Collector" -Status "Package $counter of $total" -CurrentOperation $leaf -PercentComplete $pct
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ("[{0,2}/{1}]" -f $counter, $total) -ForegroundColor DarkCyan -NoNewline
    Write-Host " " -NoNewline
    Write-Host $leaf -ForegroundColor White
    Download-File $url
}
Write-Progress -Activity "Tools Collector" -Completed

Write-Host ""
Write-TermRule -Char $U.HD -Color Cyan
Write-Host "  " -NoNewline
Write-Host "[OK]" -ForegroundColor Green -NoNewline
Write-Host " batch complete - opening folder..." -ForegroundColor Gray
Write-Host "  " -NoNewline
Write-Host $folder -ForegroundColor DarkCyan
Write-TermRule -Char $U.HD -Color Cyan
Write-Host ""

Start-Process explorer.exe $folder
