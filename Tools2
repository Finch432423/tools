# ==================================================
# FINCH'S SS TOOLS
# ==================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# ==================================================
# ADMINISTRATOR CHECK
# ==================================================

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host ""
    Write-Host "  Administrator permissions required." -ForegroundColor Yellow
    Write-Host "  Relaunching as administrator..." -ForegroundColor DarkGray
    Write-Host ""

    try {
        $scriptPath = $PSCommandPath

        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }

        $processPath = (Get-Process -Id $PID).Path

        if ($scriptPath -and (Test-Path -LiteralPath $scriptPath)) {

            $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $scriptPath

            Start-Process -FilePath $processPath -Verb RunAs -ArgumentList $arguments

        }
        elseif ([IO.Path]::GetFileName($processPath) -notmatch '^(powershell|pwsh)\.exe$') {

            # Running as a compiled EXE (for example, using PS2EXE).
            # Relaunch the same executable with administrator permissions.

            Start-Process -FilePath $processPath -Verb RunAs

        }
        else {
            throw "Could not locate the script file to relaunch."
        }

    }
    catch {
        Write-Host "  [ERROR] Unable to obtain administrator permissions." -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
        Read-Host "  Press Enter to exit"
        exit 1
    }

    exit 0
}


# ==================================================
# TERMINAL DISPLAY
# ==================================================

# Box-drawing via codepoints so the script parses even
# if the file is not UTF-8 with BOM.

$U = @{
    H   = [string][char]0x2500
    HD  = [string][char]0x2550
    V   = [string][char]0x2502
    TL  = [string][char]0x250C
    TR  = [string][char]0x2510
    BL  = [string][char]0x2514
    BR  = [string][char]0x2518
    ARR = [string][char]0x2192
}


# Enable VT processing on legacy consoles when possible.

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

        if ($t::GetConsoleMode($h, [ref]$m)) {
            [void]$t::SetConsoleMode($h, $m -bor 4)
        }

    }
    catch { }

}


function Get-TermWidth {

    try {

        $w = $Host.UI.RawUI.WindowSize.Width

        if ($w -gt 0) {
            return [Math]::Max(48, [Math]::Min(80, $w - 2))
        }

    }
    catch { }

    return 72

}


function Write-TermRule {

    param(
        [string]$Char,
        [ConsoleColor]$Color = "DarkGray"
    )

    if (-not $Char) {
        $Char = $U.H
    }

    $len = Get-TermWidth

    Write-Host ($Char * $len) -ForegroundColor $Color

}


function Write-TermHeader {

    $title = "FINCH'S SS TOOLS"
    $credit = "screenshare toolkit  |  download manager"

    $w = Get-TermWidth
    $inner = $w - 2

    Write-Host ""

    Write-Host ($U.TL + ($U.H * $inner) + $U.TR) -ForegroundColor DarkGray

    $pad = [Math]::Max(0, [Math]::Floor(($inner - $title.Length) / 2))

    Write-Host (
        $U.V +
        (" " * $pad) +
        $title +
        (" " * ($inner - $pad - $title.Length)) +
        $U.V
    ) -ForegroundColor Cyan

    Write-Host ($U.V + (" " * $inner) + $U.V) -ForegroundColor DarkGray

    if ($credit.Length -gt $inner) {
        $credit = $credit.Substring(0, [Math]::Max(0, $inner - 3)) + "..."
    }

    $cp = [Math]::Max(0, [Math]::Floor(($inner - $credit.Length) / 2))

    Write-Host (
        $U.V +
        (" " * $cp) +
        $credit +
        (" " * ($inner - $cp - $credit.Length)) +
        $U.V
    ) -ForegroundColor DarkGray

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


# ==================================================
# PACKAGE DOWNLOAD LISTS
# ==================================================

$fullUrls = @(

    # BAM Parser
    'https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe',

    # Espouken
    'https://github.com/spokwn/Tool/releases/download/v1.1.3/espouken.exe',

    # Kernel Live Dump Tool
    'https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe',

    # Paths Parser
    'https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe',

    # Prefetch Parser
    'https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe',

    # Journal Trace
    'https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTrace.exe',

    # WinPrefetchView
    'https://www.nirsoft.net/utils/winprefetchview-x64.zip',

    # System Informer
    'https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe',

    # USBDeview
    'https://www.nirsoft.net/utils/usbdeview-x64.zip',

    # Network Usage View
    'https://www.nirsoft.net/utils/networkusageview-x64.zip',

    # Timeline Explorer
    'https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip',

    # USB Drive Log
    'https://www.nirsoft.net/utils/usbdrivelog.zip',

    # Previous Files Recovery
    'https://www.nirsoft.net/utils/previousfilesrecovery-x64.zip',

    # RedLotus Mod Analyzer
    'https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe',

    # Tasks Parser
    'https://github.com/zedoonvm1/TasksParser/releases/download/1.1/Tasks.Parser.exe',

    # Fileless
    'https://github.com/Orbdiff/Fileless/releases/download/v1.1/Fileless.exe',

    # RedLotus Alt Checker
    'https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe',

    # PrefetchView++
    'https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.3/PrefetchView++.exe',

    # Everything
    'https://www.voidtools.com/Everything-1.4.1.1032.x86-Setup.exe'

)


# ==================================================
# REDUCED DOWNLOAD LIST
# ==================================================

$reducedUrls = @(

    # BAM Parser
    'https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe',

    # Espouken
    'https://github.com/spokwn/Tool/releases/download/v1.1.3/espouken.exe',

    # Journal Trace
    'https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTrace.exe',

    # Paths Parser
    'https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe',

    # Prefetch Parser
    'https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe',

    # Previous Files Recovery
    'https://www.nirsoft.net/utils/previousfilesrecovery-x64.zip',

    # RedLotus Mod Analyzer
    'https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe',

    # RedLotus Alt Checker
    'https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe',

    # System Informer
    'https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe',

    # USBDeview
    'https://www.nirsoft.net/utils/usbdeview-x64.zip'

    # VoidToils
    'https://www.voidtools.com/Everything-1.4.1.1032.x86-Setup.exe'

)


# ==================================================
# PACKAGE SELECTION MENU
# ==================================================

function Show-PackageMenu {

    while ($true) {

        Write-TermRule -Char $U.HD -Color Cyan

        Write-Host ""
        Write-Host "  SELECT YOUR DOWNLOAD PACKAGE" -ForegroundColor White
        Write-Host ""
        Write-Host "  Choose which collection you would like to install." -ForegroundColor DarkGray
        Write-Host ""

        Write-Host "  [1] FULL COLLECTION" -ForegroundColor Cyan -NoNewline
        Write-Host "   - All $($fullUrls.Count) tools" -ForegroundColor Gray

        Write-Host ""

        Write-Host "  [2] REDUCED COLLECTION" -ForegroundColor Green -NoNewline
        Write-Host " - $($reducedUrls.Count) selected tools" -ForegroundColor Gray

        Write-Host ""
        Write-Host "  [Q] EXIT" -ForegroundColor Red

        Write-Host ""

        Write-TermRule -Char $U.HD -Color Cyan

        Write-Host ""

        $choice = (Read-Host "  Enter your selection").Trim().ToUpperInvariant()

        switch ($choice) {

            "1" {
                return "1"
            }

            "2" {
                return "2"
            }

            "Q" {
                return "Q"
            }

            default {
                Write-Host ""
                Write-Host "  [!!] Invalid selection. Please choose 1, 2 or Q." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 1200
                cls
                Write-TermHeader
            }

        }

    }

}


# ==================================================
# START PROGRAM
# ==================================================

cls

Write-TermHeader

$selection = Show-PackageMenu


# ==================================================
# APPLY PACKAGE SELECTION
# ==================================================

if ($selection -eq "Q") {

    Write-Host ""
    Write-Host "  Exiting Finch's SS Tools..." -ForegroundColor DarkGray
    Write-Host ""

    exit 0

}


if ($selection -eq "1") {

    $urls = $fullUrls
    $packageLabel = "FULL COLLECTION"

}
else {

    $urls = $reducedUrls
    $packageLabel = "REDUCED COLLECTION"

}


# ==================================================
# WORKSPACE CREATION
# ==================================================

$root = "C:\"
$name = "Screenshare"

$i = 1

while (Test-Path "$root$name$i") {
    $i++
}

$folder = "$root$name$i"

New-Item -Path $folder -ItemType Directory -Force | Out-Null

Set-Location -LiteralPath $folder


Write-TermSection "workspace"

Write-Host "  " -NoNewline
Write-Host "[OK]" -ForegroundColor Green -NoNewline
Write-Host " " -NoNewline
Write-Host $folder -ForegroundColor DarkCyan

Write-Host "  " -NoNewline
Write-Host "[OK]" -ForegroundColor Green -NoNewline
Write-Host " " -NoNewline
Write-Host "Package: $packageLabel" -ForegroundColor Gray


# ==================================================
# DOWNLOAD SUPPORT
# ==================================================

function Download-File {

    param(
        [string]$Url
    )

    $fileName = Split-Path $Url -Leaf
    $dest = Join-Path $folder $fileName

    try {

        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $dest `
            -UseBasicParsing `
            -ErrorAction Stop

        Write-Host "      " -NoNewline
        Write-Host "done" -ForegroundColor Green -NoNewline
        Write-Host "  " -NoNewline
        Write-Host $fileName -ForegroundColor Gray


        # ==========================================
        # AUTOMATIC ZIP EXTRACTION
        # ==========================================

        if ($fileName.ToLowerInvariant().EndsWith(".zip")) {

            $outDir = Join-Path $folder (
                [IO.Path]::GetFileNameWithoutExtension($fileName)
            )

            New-Item -ItemType Directory -Path $outDir -Force | Out-Null

            Expand-Archive `
                -LiteralPath $dest `
                -DestinationPath $outDir `
                -Force `
                -ErrorAction Stop

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


# ==================================================
# DOWNLOAD PROCESS
# ==================================================

$counter = 0
$total = $urls.Count

Write-TermSection "downloads ($total packages)"

foreach ($url in $urls) {

    $counter++

    $leaf = Split-Path $url -Leaf

    $pct = if ($total -gt 0) {
        [int](($counter / $total) * 100)
    }
    else {
        0
    }

    Write-Progress `
        -Activity "Finch's SS Tools" `
        -Status "Package $counter of $total" `
        -CurrentOperation $leaf `
        -PercentComplete $pct

    Write-Host ""

    Write-Host "  " -NoNewline
    Write-Host ("[{0,2}/{1}]" -f $counter, $total) -ForegroundColor DarkCyan -NoNewline
    Write-Host " " -NoNewline
    Write-Host $leaf -ForegroundColor White

    Download-File $url

}


Write-Progress -Activity "Finch's SS Tools" -Completed


# ==================================================
# COMPLETION
# ==================================================

Write-Host ""

Write-TermRule -Char $U.HD -Color Cyan

Write-Host "  " -NoNewline
Write-Host "[OK]" -ForegroundColor Green -NoNewline
Write-Host " batch complete - opening folder..." -ForegroundColor Gray

Write-Host "  " -NoNewline
Write-Host $folder -ForegroundColor DarkCyan

Write-Host "  " -NoNewline
Write-Host "Package: $packageLabel" -ForegroundColor Gray

Write-TermRule -Char $U.HD -Color Cyan

Write-Host ""

Start-Process explorer.exe -ArgumentList "`"$folder`""
