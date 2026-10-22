# Install concept-scanner for the current user on Windows, with no
# administrator rights.
#
#   powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1 | iex"
#
# To remove what it installs:
#
#   powershell -ExecutionPolicy ByPass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.ps1))) -Uninstall"
#
# It runs nothing it downloaded until the release's list of checksums has been
# checked against the publisher's signature, the program against that list, and
# the program's Authenticode signature against the publisher's name.
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

# The keys that sign each release's checksums.txt, as checksums.txt.sig:
# Ed25519, base64, comma separated, the same two concept-scanner carries to
# check its own updates. A release whose signature none of them verifies installs
# nothing. Tests replace this one line with a key of their own.
$CsSigningKeys = 'vkbGnJckdjq0FiOw6kMHNDWqme3U16YiTImqvCK2+qQ=,9XAYom1DCpn/qeRU2IMVMyR4Jrfzdz8COWk09mP6J/Y='

# Whom the downloaded program's Authenticode signature must name: the
# publisher, as its certificate's common name and organization, and the
# organization of the authority that issued that certificate. Tests replace
# this one line.
$CsWindowsSigner = @{ CN = 'Geeks in the Woods'; O = 'Geeks in the Woods'; IssuerO = 'Microsoft Corporation' }

# A known answer the signature check must give before its answer about a
# release is believed: RFC 8032's second Ed25519 test vector (the one-byte
# message "r") verifies, and the same key with a signature whose R is the
# identity point and whose S is zero does not.
$CsTestKey = 'PUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw='
$CsTestSig = 'kqAJqfDUyrhyDoILX2QlQKKye1QWUD+Ps3YiI+vbadoIWsHkPhWZbkWPNhPQ8R2MOHsurrQwKu6wDSkWErsMAA=='
$CsTestForged = 'AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=='

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

# The Ed25519 check below. Windows has no command that checks an Ed25519
# signature, so it is done here as RFC 8032 describes it and as Go's
# crypto/ed25519 does it, with .NET's BigInteger and SHA-512. Every operation is
# a BigInteger method rather than an operator, so nothing is converted to a
# floating-point number on the way.
$CsP = [System.Numerics.BigInteger]::Subtract([System.Numerics.BigInteger]::Pow(2, 255), 19)
$CsL = [System.Numerics.BigInteger]::Add([System.Numerics.BigInteger]::Pow(2, 252), [System.Numerics.BigInteger]::Parse('27742317777372353535851937790883648493'))

function Get-CsMod($A) {
    $r = [System.Numerics.BigInteger]::Remainder($A, $CsP)
    if ($r.Sign -lt 0) { $r = [System.Numerics.BigInteger]::Add($r, $CsP) }
    $r
}

function Get-CsMul($A, $B) {
    Get-CsMod ([System.Numerics.BigInteger]::Multiply($A, $B))
}

function Get-CsInverse($A) {
    [System.Numerics.BigInteger]::ModPow((Get-CsMod $A), [System.Numerics.BigInteger]::Subtract($CsP, 2), $CsP)
}

# ConvertFrom-CsLittleEndian reads bytes as an unsigned little-endian number.
function ConvertFrom-CsLittleEndian([byte[]]$Bytes) {
    $b = New-Object byte[] ($Bytes.Length + 1)
    [Array]::Copy($Bytes, $b, $Bytes.Length)
    New-Object System.Numerics.BigInteger (, $b)
}

# Get-CsCurve computes the curve's constants once: d, 2d, a square root of -1,
# and the base point from y = 4/5.
function Get-CsCurve {
    if ($script:CsCurve) { return $script:CsCurve }
    $d = Get-CsMul (-121665) (Get-CsInverse 121666)
    $curve = @{ D = $d; D2 = (Get-CsMul 2 $d); Sqrt = [System.Numerics.BigInteger]::ModPow(2, [System.Numerics.BigInteger]::Divide([System.Numerics.BigInteger]::Subtract($CsP, 1), 4), $CsP) }
    $script:CsCurve = $curve
    $by = Get-CsMul 4 (Get-CsInverse 5)
    $bx = Get-CsPointX $by 0
    $curve.B = @($bx, $by, [System.Numerics.BigInteger]::One, (Get-CsMul $bx $by))
    $curve
}

# Get-CsPointX is the x of the point whose y is $Y and whose x has parity
# $Sign, or $null when there is none.
function Get-CsPointX($Y, [int]$Sign) {
    $c = $script:CsCurve
    if ([System.Numerics.BigInteger]::Compare($Y, $CsP) -ge 0) { return $null }
    $y2 = Get-CsMul $Y $Y
    $u = Get-CsMod ([System.Numerics.BigInteger]::Subtract($y2, 1))
    $v = Get-CsMod ([System.Numerics.BigInteger]::Add([System.Numerics.BigInteger]::Multiply($c.D, $y2), 1))
    $v3 = Get-CsMul (Get-CsMul $v $v) $v
    $v7 = Get-CsMul (Get-CsMul $v3 $v3) $v
    $e = [System.Numerics.BigInteger]::Divide([System.Numerics.BigInteger]::Subtract($CsP, 5), 8)
    $x = Get-CsMul (Get-CsMul $u $v3) ([System.Numerics.BigInteger]::ModPow((Get-CsMul $u $v7), $e, $CsP))
    $check = Get-CsMul (Get-CsMul $v $x) $x
    if ([System.Numerics.BigInteger]::Compare($check, $u) -ne 0) {
        if ([System.Numerics.BigInteger]::Compare($check, (Get-CsMod ([System.Numerics.BigInteger]::Negate($u)))) -ne 0) { return $null }
        $x = Get-CsMul $x $c.Sqrt
    }
    if ($x.IsZero -and $Sign -eq 1) { return $null }
    if ([int](-not $x.IsEven) -ne $Sign) { $x = [System.Numerics.BigInteger]::Subtract($CsP, $x) }
    $x
}

# Add-CsPoint adds two points in extended coordinates (x, y, z, t). It is the
# loop's whole cost, so it calls no function of its own and leaves each
# coordinate between -p and p, which the formulas allow; the result is made
# positive once, at the end.
function Add-CsPoint($P1, $P2) {
    $n = [System.Numerics.BigInteger]
    $a = $n::Remainder($n::Multiply($n::Subtract($P1[1], $P1[0]), $n::Subtract($P2[1], $P2[0])), $CsP)
    $b = $n::Remainder($n::Multiply($n::Add($P1[1], $P1[0]), $n::Add($P2[1], $P2[0])), $CsP)
    $c = $n::Remainder($n::Multiply($n::Remainder($n::Multiply($script:CsCurve.D2, $P1[3]), $CsP), $P2[3]), $CsP)
    $k = $n::Remainder($n::Multiply($n::Add($P1[2], $P1[2]), $P2[2]), $CsP)
    $e = $n::Subtract($b, $a)
    $f = $n::Subtract($k, $c)
    $g = $n::Add($k, $c)
    $h = $n::Add($b, $a)
    @($n::Remainder($n::Multiply($e, $f), $CsP), $n::Remainder($n::Multiply($g, $h), $CsP), $n::Remainder($n::Multiply($f, $g), $CsP), $n::Remainder($n::Multiply($e, $h), $CsP))
}

# Test-CsEd25519 is true when $Signature is an Ed25519 signature by $Key over
# $Message.
function Test-CsEd25519([byte[]]$Key, [byte[]]$Message, [byte[]]$Signature) {
    if ($Key.Length -ne 32 -or $Signature.Length -ne 64) { return $false }
    $curve = Get-CsCurve
    $keyBytes = [byte[]]$Key.Clone()
    $sign = ($keyBytes[31] -shr 7) -band 1
    $keyBytes[31] = $keyBytes[31] -band 0x7f
    $ay = ConvertFrom-CsLittleEndian $keyBytes
    $ax = Get-CsPointX $ay $sign
    if ($null -eq $ax) { return $false }
    $s = ConvertFrom-CsLittleEndian ($Signature[32..63])
    if ([System.Numerics.BigInteger]::Compare($s, $CsL) -ge 0) { return $false }
    $buffer = New-Object byte[] (64 + $Message.Length)
    [Array]::Copy($Signature, 0, $buffer, 0, 32)
    [Array]::Copy($Key, 0, $buffer, 32, 32)
    [Array]::Copy($Message, 0, $buffer, 64, $Message.Length)
    $sha = [System.Security.Cryptography.SHA512]::Create()
    try { $digest = $sha.ComputeHash($buffer) } finally { $sha.Dispose() }
    $k = [System.Numerics.BigInteger]::Remainder((ConvertFrom-CsLittleEndian $digest), $CsL)

    # [s]B - [k]A, both scalars at once, with B - A precomputed.
    $nx = Get-CsMod ([System.Numerics.BigInteger]::Negate($ax))
    $minusA = @($nx, $ay, [System.Numerics.BigInteger]::One, (Get-CsMul $nx $ay))
    $both = Add-CsPoint $curve.B $minusA
    # Each scalar as 256 bits, least significant first.
    $sBytes = $s.ToByteArray()
    $kBytes = $k.ToByteArray()
    $sBits = New-Object int[] 256
    $kBits = New-Object int[] 256
    for ($i = 0; $i -lt 256; $i++) {
        $byte = $i -shr 3
        if ($byte -lt $sBytes.Length) { $sBits[$i] = ($sBytes[$byte] -shr ($i -band 7)) -band 1 }
        if ($byte -lt $kBytes.Length) { $kBits[$i] = ($kBytes[$byte] -shr ($i -band 7)) -band 1 }
    }
    $q = @([System.Numerics.BigInteger]::Zero, [System.Numerics.BigInteger]::One, [System.Numerics.BigInteger]::One, [System.Numerics.BigInteger]::Zero)
    $started = $false
    for ($i = 255; $i -ge 0; $i--) {
        # Doubling the identity changes nothing, so it starts at the first set bit.
        if ($started) { $q = Add-CsPoint $q $q }
        $pick = $sBits[$i] + 2 * $kBits[$i]
        if ($pick -eq 1) { $q = Add-CsPoint $q $curve.B }
        elseif ($pick -eq 2) { $q = Add-CsPoint $q $minusA }
        elseif ($pick -eq 3) { $q = Add-CsPoint $q $both }
        if ($pick -ne 0) { $started = $true }
    }

    # It verifies when that point's encoding is the signature's R.
    $zi = Get-CsInverse $q[2]
    $x = Get-CsMul $q[0] $zi
    $y = Get-CsMul $q[1] $zi
    if (-not $x.IsEven) { $y = [System.Numerics.BigInteger]::Add($y, [System.Numerics.BigInteger]::Pow(2, 255)) }
    [System.Numerics.BigInteger]::Compare($y, (ConvertFrom-CsLittleEndian ($Signature[0..31]))) -eq 0
}

# Test-CsSigned accepts only a single true answer, so that a stray value a
# function writes to its output, which PowerShell would return with the answer,
# can never read as a signature that verifies.
function Test-CsSigned([byte[]]$Key, [byte[]]$Message, [byte[]]$Signature) {
    $answer = @(Test-CsEd25519 $Key $Message $Signature)
    ($answer.Count -eq 1) -and ($answer[0] -is [bool]) -and $answer[0]
}

# Assert-CsSignedList throws unless the release's checksums.txt carries a
# signature, checksums.txt.sig, from one of the release keys. The check must
# first give the known answers above.
function Assert-CsSignedList([string]$Sums, [string]$Sig) {
    $testKey = [Convert]::FromBase64String($CsTestKey)
    $testMessage = [Text.Encoding]::ASCII.GetBytes('r')
    if (-not (Test-CsSigned $testKey $testMessage ([Convert]::FromBase64String($CsTestSig))) -or
        (Test-CsSigned $testKey $testMessage ([Convert]::FromBase64String($CsTestForged)))) {
        throw ('The signature check gave the wrong answer on a known signature here, so nothing was installed. ' +
            'Please report it on the issue tracker with this message; meanwhile the container image, or WSL, runs it. See the README.')
    }
    $message = [IO.File]::ReadAllBytes($Sums)
    $signature = $null
    try { $signature = [Convert]::FromBase64String(([IO.File]::ReadAllText($Sig)).Trim()) } catch { }
    if ($null -ne $signature) {
        foreach ($key in ($CsSigningKeys -split ',')) {
            if (Test-CsSigned ([Convert]::FromBase64String($key)) $message $signature) { return }
        }
    }
    throw ("The release's checksums.txt is not signed by the concept-scanner release key, so nothing was installed. " +
        'A proxy or a captive portal that answered with its own page is the usual cause; try another network. ' +
        'If it happens on a network you trust, please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security')
}

# Get-CsNamePart is one part (CN, O) of a certificate's distinguished name.
function Get-CsNamePart([string]$Name, [string]$Part) {
    foreach ($m in [regex]::Matches($Name, '(?:^|,)\s*([A-Za-z]+)=("(?:[^"]|"")*"|[^,]*)')) {
        if ($m.Groups[1].Value -eq $Part) { return $m.Groups[2].Value.Trim().Trim('"') }
    }
    $null
}

# Import-CsSecurityModule loads the module Get-AuthenticodeSignature lives in
# from this PowerShell's own folder. Windows PowerShell 5.1 started from
# PowerShell 7 inherits 7's module path, finds 7's copy of the module first and
# cannot load it, so the command is not found (see Get-CsSha256).
function Import-CsSecurityModule {
    if (-not (Get-Module Microsoft.PowerShell.Security)) {
        Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Security\Microsoft.PowerShell.Security.psd1')
    }
}

# Assert-CsWindowsSignature throws unless the file carries a valid Authenticode
# signature from the publisher $CsWindowsSigner names.
function Assert-CsWindowsSignature([string]$Path, [string]$Asset) {
    Import-CsSecurityModule
    $sig = Get-AuthenticodeSignature -LiteralPath $Path
    $cert = $sig.SignerCertificate
    if ($sig.Status -ne 'Valid' -or $null -eq $cert -or
        (Get-CsNamePart $cert.Subject 'CN') -ne $CsWindowsSigner.CN -or
        (Get-CsNamePart $cert.Subject 'O') -ne $CsWindowsSigner.O -or
        (Get-CsNamePart $cert.Issuer 'O') -ne $CsWindowsSigner.IssuerO) {
        throw ("$Asset does not carry the publisher's Authenticode signature ($($sig.Status)), so nothing was installed. " +
            'Please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security')
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
        $sumsSig = Join-Path $tmp 'checksums.txt.sig'
        Invoke-WebRequest -UseBasicParsing -Uri "$CsReleases/checksums.txt.sig" -OutFile $sumsSig

        # The checksum below proves the download is the file the release lists;
        # the signature proves the list is the publisher's, which a checksum from
        # the same place cannot.
        Assert-CsSignedList $sums $sumsSig
        Write-Host "The release's signature verifies."

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
        Assert-CsWindowsSignature $file $asset

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
    # The extraction cache, in the folder Go's os.UserCacheDir names on Windows:
    # it regenerates on the next scan and holds extractions of every repository
    # scanned, so uninstalling removes it.
    $cache = Join-Path $env:LOCALAPPDATA 'concept-scanner'
    if (Test-Path -LiteralPath $cache) {
        Remove-Item -LiteralPath $cache -Recurse -Force
    }
    Write-Host "Removed $dir, its PATH entry, and the extraction cache, $cache."
    # Your scans, settings and saved keys are yours to delete.
    $kept = Join-Path $env:USERPROFILE '.concept-scanner'
    if (Test-Path -LiteralPath $kept) {
        Write-Host "Kept ${kept}: your scans, settings and any API keys you saved."
        Write-Host "To delete them too: Remove-Item -Recurse -Force '$kept'"
    }
}

if ($Uninstall) { Uninstall-ConceptScanner } else { Install-ConceptScanner }
