[CmdletBinding()]
param(
    [switch]$SkipDependencies,
    [switch]$SkipChecks,
    [switch]$Fresh,
    [ValidateRange(1, 64)][int]$Jobs = 4
)

$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process Bypass -Force
$repo = $PSScriptRoot
$deps = Join-Path $repo 'build\deps'
$build = Join-Path $repo 'build\windows'
$stage = Join-Path $repo 'build\host-win-x64'

function First-Existing([string[]]$Candidates) {
    foreach ($candidate in $Candidates) { if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate } }
    return $null
}
function Resolve-App([string]$Name, [string[]]$Candidates) {
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    $found = First-Existing $Candidates
    if ($found) { return $found }
    throw "Cannot find $Name"
}

$vsRoot = if (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe') {
    & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -latest -products * -property installationPath
}
$cmake = Resolve-App 'cmake.exe' @($(if ($vsRoot) { Join-Path $vsRoot 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' }), 'C:\Program Files\CMake\bin\cmake.exe')
$ctest = Resolve-App 'ctest.exe' @((Join-Path (Split-Path $cmake -Parent) 'ctest.exe'))
$compiler = Resolve-App 'g++.exe' @('C:\msys64\ucrt64\bin\g++.exe')
$cc = Resolve-App 'gcc.exe' @((Join-Path (Split-Path $compiler -Parent) 'gcc.exe'))
$ninja = Resolve-App 'ninja.exe' @('C:\msys64\ucrt64\bin\ninja.exe', $(if ($vsRoot) { Join-Path $vsRoot 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe' }))
$python = Resolve-App 'python.exe' @(
    'C:\Users\hongy\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe',
    'C:\msys64\ucrt64\bin\python.exe'
)
$glslang = Resolve-App 'glslangValidator.exe' @('C:\VulkanSDK\1.4.363.0\Bin\glslangValidator.exe')
$vulkanInclude = First-Existing @($(if ($env:VULKAN_SDK) { Join-Path $env:VULKAN_SDK 'Include\vulkan\vulkan.h' }), 'C:\VulkanSDK\1.4.363.0\Include\vulkan\vulkan.h')
if (-not $vulkanInclude) { throw 'Cannot find Vulkan headers.' }
$vulkanInclude = Split-Path (Split-Path $vulkanInclude -Parent) -Parent
$cargo = Resolve-App 'cargo.exe' @((Join-Path $env:USERPROFILE '.cargo\bin\cargo.exe'))
$node = Resolve-App 'node.exe' @('C:\Program Files\nodejs\node.exe')
$npm = Resolve-App 'npm.cmd' @('C:\Program Files\nodejs\npm.cmd')
$env:Path = ((Split-Path $cargo -Parent), (Split-Path $glslang -Parent), (Split-Path $compiler -Parent), (Split-Path $node -Parent), $env:Path) -join [IO.Path]::PathSeparator

# The official packager deliberately pins the portable CLI runtime even when
# another compatible Node drives npm/Tauri. Download that exact binary and
# verify the published digest before exposing it to build-agent.mjs.
$nodeRuntime = Join-Path $repo 'desktop\.cache\node-v24.19.0-win-x64\node.exe'
$nodeRuntimeSha256 = '3602F2BB1A10F2CBAB4C36886218A33C1AB3DB87290E73B033C46C77147D0237'
$nodeRuntimeValid = (Test-Path -LiteralPath $nodeRuntime -PathType Leaf) -and
    ((Get-FileHash -LiteralPath $nodeRuntime -Algorithm SHA256).Hash -eq $nodeRuntimeSha256)
if (-not $nodeRuntimeValid) {
    New-Item -ItemType Directory -Path (Split-Path $nodeRuntime -Parent) -Force | Out-Null
    Invoke-WebRequest -Uri 'https://nodejs.org/dist/v24.19.0/win-x64/node.exe' -OutFile $nodeRuntime
    if ((Get-FileHash -LiteralPath $nodeRuntime -Algorithm SHA256).Hash -ne $nodeRuntimeSha256) {
        Remove-Item -LiteralPath $nodeRuntime -Force
        throw 'The downloaded Node v24.19.0 runtime did not match its published SHA-256.'
    }
}
$env:SPEKTRALAB_NODE_RUNTIME = $nodeRuntime

if (-not $SkipDependencies) {
    & (Join-Path $repo 'engine\setup-libraw.ps1') -DependencyDirectory $deps
    if ($LASTEXITCODE) { throw "LibRaw setup failed ($LASTEXITCODE)." }
    & (Join-Path $repo 'engine\setup-codecs.ps1') -DependencyDirectory (Join-Path $deps 'export-codecs')
    if ($LASTEXITCODE) { throw "Export codec setup failed ($LASTEXITCODE)." }
    & $python (Join-Path $repo 'engine\setup-input-codecs.py') `
        --sources (Join-Path $deps 'input-codecs\sources') --build (Join-Path $deps 'input-codecs\build') `
        --install (Join-Path $deps 'input-codecs\install') --cmake $cmake --generator Ninja `
        --cc $cc --cxx $compiler --make $ninja --jobs $Jobs
    if ($LASTEXITCODE) { throw "Input codec build failed ($LASTEXITCODE)." }
    & $python -m pip install --disable-pip-version-check --quiet 'meson==1.9.2'
    if ($LASTEXITCODE) { throw "Meson setup failed ($LASTEXITCODE)." }
    & $python (Join-Path $repo 'engine\setup-lens-codecs.py') `
        --sources (Join-Path $deps 'lens-codecs\sources') --build (Join-Path $deps 'lens-codecs\build') `
        --install (Join-Path $deps 'lens-codecs\install') --cmake $cmake --generator Ninja `
        --cc $cc --cxx $compiler --make $ninja --jobs $Jobs
    if ($LASTEXITCODE) { throw "Lens dependency build failed ($LASTEXITCODE)." }
}

& (Join-Path $repo 'engine\build-windows.ps1') -BuildDirectory $build -CMakeExecutable $cmake `
    -CTestExecutable $ctest -Compiler $compiler -MakeExecutable $ninja -DependencyDirectory $deps `
    -VulkanIncludeDirectory $vulkanInclude -GlslangExecutable $glslang `
    -LibRawSourceDirectory (Join-Path $deps 'LibRaw-0.22.2') `
    -InputCodecPrefix (Join-Path $deps 'input-codecs\install') `
    -LensPrefix (Join-Path $deps 'lens-codecs\install') `
    -HostBuild -NativeRaw -Desktop:$false -Fresh:$Fresh -Jobs $Jobs
if ($LASTEXITCODE) { throw "Engine build failed ($LASTEXITCODE)." }

& (Join-Path $repo 'engine\stage-host-windows.ps1') -BuildDirectory $build -StageDirectory $stage -DependencyDirectory $deps

Push-Location (Join-Path $repo 'desktop')
try {
    & $npm ci
    if ($LASTEXITCODE) { throw "npm ci failed ($LASTEXITCODE)." }
    if (-not $SkipChecks) { & $npm run check }
    if (-not $SkipChecks -and $LASTEXITCODE) { throw "Frontend checks failed ($LASTEXITCODE)." }
    & $npm run package:windows -- --host-dir $stage
    if ($LASTEXITCODE) { throw "Windows packaging failed ($LASTEXITCODE)." }
} finally { Pop-Location }

$installer = Get-ChildItem -Path (Join-Path $repo 'desktop\release\windows') -Filter '*-setup.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $installer) { throw 'The Windows installer was not produced.' }
Write-Output "Windows installer: $($installer.FullName)"
