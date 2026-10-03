# Install concept-scanner for the current user on Windows, with no
# administrator rights.
#
#   powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1 | iex"
#
# To remove what it installs:
#
#   powershell -ExecutionPolicy ByPass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1))) -Uninstall"
#
# Running it again installs the latest release over the copy you have. After
# that, `concept-scanner update` checks and installs new releases.
#
# Written for Windows PowerShell 5.1, the version every Windows ships. Every
# function is defined before the last line runs one, so a download cut off part
# way runs nothing. Failures throw rather than exit: under `iex`, exit would
# close the window and take the message with it.

param([switch]$Uninstall)

# Where releases are downloaded from. Tests replace this one line with a local
# server; nothing at run time changes it.
$CsReleases = 'https://github.com/Obviously-Not/concept-scanner-public/releases/latest/download'

function Get-CsProgramDir {
    Join-Path $env:LOCALAPPDATA 'Programs\concept-scanner'
}

# Move-CsWithRetry renames, retrying for two seconds: antivirus commonly holds a
# freshly written .exe open for a moment, and a running .exe can be renamed but
# not overwritten.
function Move-CsWithRetry([string]$From, [string]$To) {
    $deadline = (Get-Date).AddSeconds(2)
    while ($true) {
        try {
            Move-Item -LiteralPath $From -Destination $To -Force -ErrorAction Stop
            return
        } catch {
            if ((Get-Date) -gt $deadline) { throw }
            Start-Sleep -Milliseconds 50
        }
    }
}

# Send-CsSettingChange tells running programs the environment changed, so a new
# terminal sees the PATH without signing out. Not fatal if it fails: the next
# sign-in picks the PATH up regardless.
function Send-CsSettingChange {
    try {
        if (-not ('CsNative.Env' -as [type])) {
            Add-Type -Namespace CsNative -Name Env -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
        }
        $result = [UIntPtr]::Zero
        # HWND_BROADCAST, WM_SETTINGCHANGE, SMTO_ABORTIFHUNG, five seconds.
        [void][CsNative.Env]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
    } catch {
    }
}

# Get-CsUserPath reads the user's Path AS STORED. Reading it through the
# environment, or writing it back with [Environment]::SetEnvironmentVariable,
# would expand every %VARIABLE% entry and store the result as plain text,
# freezing them; so the registry is read without expansion and written back as
# REG_EXPAND_SZ.
function Get-CsUserPath {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
    try {
        if ($null -eq $key) { return '' }
        return [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    } finally {
        if ($null -ne $key) { $key.Close() }
    }
}

function Set-CsUserPath([string]$Value) {
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
    try {
        $key.SetValue('Path', $Value, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    } finally {
        $key.Close()
    }
    Send-CsSettingChange
}

# Get-CsSha256 hashes with .NET directly. Not Get-FileHash: in Windows
# PowerShell 5.1 that is a script function in a module that does not load when
# the process inherits PowerShell 7's module path, which is what happens when the
# documented one-liner is started from a PowerShell 7 terminal. The windows CI
# job, whose steps run in PowerShell 7, found it on the script's first run.
function Get-CsSha256([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '').ToLowerInvariant()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

function Test-CsSamePath([string]$Entry, [string]$Dir) {
    [Environment]::ExpandEnvironmentVariables($Entry).TrimEnd('\') -ieq $Dir.TrimEnd('\')
}

# Add-CsUserPath appends the folder unless an entry already names it. Entries
# are compared whole, split on ';', never by substring.
function Add-CsUserPath([string]$Dir) {
    $raw = Get-CsUserPath
    foreach ($entry in ($raw -split ';')) {
        if ($entry -ne '' -and (Test-CsSamePath $entry $Dir)) { return $false }
    }
    if ($raw -eq '') {
        $new = $Dir
    } elseif ($raw.EndsWith(';')) {
        $new = $raw + $Dir
    } else {
        $new = $raw + ';' + $Dir
    }
    Set-CsUserPath $new
    $env:Path = "$env:Path;$Dir"
    return $true
}

function Remove-CsUserPath([string]$Dir) {
    $raw = Get-CsUserPath
    $entries = @($raw -split ';')
    $kept = @($entries | Where-Object { -not ($_ -ne '' -and (Test-CsSamePath $_ $Dir)) })
    if ($kept.Count -eq $entries.Count) { return $false }
    Set-CsUserPath ($kept -join ';')
    return $true
}

function Install-ConceptScanner {
    $ErrorActionPreference = 'Stop'
    # Windows PowerShell 5.1 downloads slowly while it draws a progress bar.
    $ProgressPreference = 'SilentlyContinue'
    # Add TLS 1.2 to what the system allows, rather than replacing the list,
    # which would drop TLS 1.3 where it exists.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $asset = 'concept-scanner-windows-amd64.exe'
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        Write-Host 'This is Windows on Arm, which runs the amd64 build under emulation; no Arm build is published.'
    }
    $dir = Get-CsProgramDir
    $dest = Join-Path $dir 'concept-scanner.exe'
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('concept-scanner-install-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        Write-Host "Downloading $asset ..."
        $file = Join-Path $tmp $asset
        $sums = Join-Path $tmp 'checksums.txt'
        # -UseBasicParsing on every call: since the December 2025 security update
        # (CVE-2025-54100), Windows PowerShell 5.1 stops at a confirmation prompt
        # without it, and an unattended install would wait forever.
        Invoke-WebRequest -UseBasicParsing -Uri "$CsReleases/$asset" -OutFile $file
        Invoke-WebRequest -UseBasicParsing -Uri "$CsReleases/checksums.txt" -OutFile $sums

        $want = $null
        foreach ($line in Get-Content -LiteralPath $sums) {
            $fields = $line.Trim() -split '\s+'
            if ($fields.Count -eq 2 -and $fields[1] -eq $asset) {
                $want = $fields[0].ToLowerInvariant()
                break
            }
        }
        if (-not $want) {
            throw "The release's checksums.txt lists no $asset, so nothing was installed."
        }
        $got = Get-CsSha256 $file
        if ($got -ne $want) {
            throw ("$asset does not match its checksum, so nothing was installed. " +
                'A proxy or a captive portal that answered with its own page is the usual cause; try another network. ' +
                'If it happens on a network you trust, please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security')
        }

        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $staged = Join-Path $dir ('.concept-scanner-install-' + [Guid]::NewGuid().ToString('N') + '.exe')
        Copy-Item -LiteralPath $file -Destination $staged
        # Run the new copy before it replaces anything. Any failure to start gets
        # one message: no particular error code is relied on.
        # Its output is collected whole: redirecting a native program's stderr
        # while errors stop the script, or cutting the pipeline short, can turn a
        # clean run into an error in Windows PowerShell 5.1.
        try {
            $out = & $staged version
            $code = $LASTEXITCODE
            if ($code -ne 0) { throw "it exited with code $code" }
            $version = @($out)[0]
        } catch {
            Remove-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue
            throw ("Windows did not run the downloaded program ($($_.Exception.Message)), so nothing was installed. " +
                'The program is signed, so antivirus software or a policy your organization sets (App Control, or Smart App Control on a managed PC) is the usual cause. ' +
                'Please report it on the issue tracker with this message; meanwhile the container image, or WSL, runs it. See the README.')
        }
        if (Test-Path -LiteralPath $dest) {
            # A running copy can be renamed but not overwritten. The program
            # removes the .old copy itself the next time it starts.
            Remove-Item -LiteralPath "$dest.old" -Force -ErrorAction SilentlyContinue
            Move-CsWithRetry $dest "$dest.old"
        }
        Move-CsWithRetry $staged $dest
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    $added = Add-CsUserPath $dir
    Write-Host "Installed $version at $dest"
    if ($added) {
        Write-Host "Added $dir to your PATH. Open a new terminal to use it."
    }
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host 'concept-scanner reads code with a model on this machine, through Ollama, which was not found on your PATH.'
        Write-Host 'If it is not installed: https://ollama.com/download'
    }
    Write-Host 'Next: concept-scanner scan .'
}

function Uninstall-ConceptScanner {
    $ErrorActionPreference = 'Stop'
    $dir = Get-CsProgramDir
    if (Test-Path -LiteralPath $dir) {
        Remove-Item -LiteralPath $dir -Recurse -Force
    }
    [void](Remove-CsUserPath $dir)
    $settings = Join-Path $env:USERPROFILE '.concept-scanner'
    if (Test-Path -LiteralPath $settings) {
        Remove-Item -LiteralPath $settings -Recurse -Force
    }
    Write-Host "Removed $dir, its PATH entry, and $settings."
    Write-Host "Scan results in each project's data folder are left alone."
}

if ($Uninstall) { Uninstall-ConceptScanner } else { Install-ConceptScanner }
