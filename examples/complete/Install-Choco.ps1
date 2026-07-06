# Runs on every instance at first boot via the CustomScriptExtension (encoded into
# commandToExecute with textencodebase64, PowerShell's -EncodedCommand wants UTF-16LE).
# Bootstraps LibreDevOpsHelpers for structured logging and retries, then Chocolatey and a couple
# of everyday tools, everything wrapped in retries with exponential backoff because first-boot
# networking and the community feed are both flaky at the worst moments.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'The Invoke-Expression is Chocolatey''s official install one-liner, executed against the vendor URL.')]
param()

$ErrorActionPreference = 'Stop'

try {
    # TLS floor for the bootstrap downloads.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # LibreDevOpsHelpers brings Write-LdoLog, Invoke-LdoWithRetry, and Assert-LdoChocoPath;
    # PSGallery needs the NuGet provider and trusting once on a fresh image.
    if (-not (Get-Module -ListAvailable -Name LibreDevOpsHelpers)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name LibreDevOpsHelpers -Scope AllUsers -Force
    }
    Import-Module LibreDevOpsHelpers

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Invoke-LdoWithRetry -OperationName 'chocolatey bootstrap' -MaxRetries 3 -ScriptBlock {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }
    Assert-LdoChocoPath

    foreach ($package in @('curl', '7zip')) {
        Invoke-LdoWithRetry -OperationName "choco install $package" -MaxRetries 3 -ScriptBlock {
            & choco install $package --yes --no-progress --limit-output
            # Chocolatey's documented success codes; anything else throws and the retry kicks in.
            if ($LASTEXITCODE -notin @(0, 1605, 1614, 1641, 3010)) {
                throw "choco install $package exited with $LASTEXITCODE"
            }
        }
    }

    Write-LdoLog -Level SUCCESS -Message 'First-boot setup complete: Chocolatey, curl, 7zip.'
}
catch {
    # A non-zero exit makes the CustomScriptExtension (and the E2E behind it) report the failure.
    if (Get-Command Write-LdoLog -ErrorAction SilentlyContinue) {
        Write-LdoLog -Level ERROR -Message "First-boot setup failed: $($_.Exception.Message)"
    }
    else {
        Write-Error "First-boot setup failed: $($_.Exception.Message)"
    }
    exit 1
}
