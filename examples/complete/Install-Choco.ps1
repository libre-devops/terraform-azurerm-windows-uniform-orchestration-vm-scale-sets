# Runs on every instance at first boot via the CustomScriptExtension (downloaded through fileUris
# and executed with -File: inlining via -EncodedCommand hits cmd.exe's 8191-character limit).
# Bootstraps Chocolatey and a couple of everyday tools, wrapped in try/catch and retries with
# exponential backoff, because first-boot networking and the community feed are both flaky at the
# worst moments.
#
# NOTE: the CustomScriptExtension runs WINDOWS POWERSHELL 5.1, and LibreDevOpsHelpers requires
# PowerShell 7.2+, so the retry helper here is local and 5.1-compatible by design (proven live:
# Install-Module succeeded but Import-Module refused the module on 5.1).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'The Invoke-Expression is Chocolatey''s official install one-liner, executed against the vendor URL.')]
param()

$ErrorActionPreference = 'Stop'

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)][scriptblock] $ScriptBlock,
        [Parameter(Mandatory)][string] $OperationName,
        [int] $MaxAttempts = 3,
        [int] $InitialDelaySeconds = 5
    )
    $delay = $InitialDelaySeconds
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            & $ScriptBlock
            return
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "$OperationName failed after $MaxAttempts attempts: $($_.Exception.Message)"
            }
            Write-Output "$OperationName attempt $attempt failed ($($_.Exception.Message)); retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
            $delay = $delay * 2
        }
    }
}

try {
    # TLS floor for the bootstrap downloads.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Invoke-WithRetry -OperationName 'chocolatey bootstrap' -ScriptBlock {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }

    $choco = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
    if (-not (Test-Path $choco)) {
        throw "Chocolatey bootstrap finished but $choco is missing."
    }

    foreach ($package in @('curl', '7zip')) {
        Invoke-WithRetry -OperationName "choco install $package" -ScriptBlock {
            & $choco install $package --yes --no-progress --limit-output
            # Chocolatey's documented success codes; anything else throws and the retry kicks in.
            if ($LASTEXITCODE -notin @(0, 1605, 1614, 1641, 3010)) {
                throw "choco install $package exited with $LASTEXITCODE"
            }
        }
    }

    Write-Output 'First-boot setup complete: Chocolatey, curl, 7zip.'
}
catch {
    # A non-zero exit makes the CustomScriptExtension (and the E2E behind it) report the failure.
    Write-Error "First-boot setup failed: $($_.Exception.Message)"
    exit 1
}
