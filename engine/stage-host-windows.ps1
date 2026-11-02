[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BuildDirectory,
    [Parameter(Mandatory)][string]$StageDirectory,
    [Parameter(Mandatory)][string]$DependencyDirectory
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$BuildDirectory = [IO.Path]::GetFullPath($BuildDirectory)
$StageDirectory = [IO.Path]::GetFullPath($StageDirectory)
$DependencyDirectory = [IO.Path]::GetFullPath($DependencyDirectory)
$partial = "$StageDirectory.partial"
$hostExecutable = Join-Path $BuildDirectory 'engine\host\spektralab-host.exe'
$resources = Join-Path $BuildDirectory 'engine\resources'

if (-not (Test-Path -LiteralPath $hostExecutable -PathType Leaf)) { throw "Missing engine host: $hostExecutable" }
if (-not (Test-Path -LiteralPath (Join-Path $resources 'vulkan') -PathType Container)) {
    throw "Missing compiled Vulkan resources: $resources"
}

if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $partial 'engine') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $partial 'licenses') -Force | Out-Null
Copy-Item -LiteralPath $hostExecutable -Destination (Join-Path $partial 'spektralab-host.exe')
Copy-Item -Path (Join-Path $resources '*') -Destination (Join-Path $partial 'engine') -Recurse

$licenses = Join-Path $partial 'licenses'
$copies = @(
    @((Join-Path $repo 'license\LICENSE'), 'SpektraLab-GPL-3.0.txt'),
    @((Join-Path $repo 'license\SPEKTRAFILM_LICENSE.txt'), 'spektrafilm-LICENSE.txt'),
    @((Join-Path $repo 'modern_UI\Spektrafilm\Spektrafilm\Resources\Licenses\Profiles-and-LUTs-CC-BY-SA-4.0.txt'), 'Profiles-and-LUTs-CC-BY-SA-4.0.txt'),
    @((Join-Path $repo 'modern_UI\Spektrafilm\Spektrafilm\Resources\Licenses\Profiles-and-LUTs-CHANGELOG.txt'), 'Profiles-and-LUTs-CHANGELOG.txt'),
    @((Join-Path $repo 'engine\resources_product\NOTICE.md'), 'Product-profiles-NOTICE.md'),
    @((Join-Path $repo 'engine\resources_product\fonts\LICENSE'), 'Imprint-fonts-LICENSE.txt'),
    @((Join-Path $repo 'engine\resources_product\fonts\DejaVu-LICENSE'), 'Imprint-mono-font-DejaVu-LICENSE.txt'),
    @((Join-Path $repo 'engine\third_party\stb\LICENSE'), 'stb-LICENSE.txt'),
    @((Join-Path $repo 'engine\third_party\volk\LICENSE.md'), 'volk-LICENSE.txt'),
    @((Join-Path $DependencyDirectory 'LibRaw-0.22.2\LICENSE.LGPL'), 'LibRaw-LGPL-2.1.txt'),
    @((Join-Path $DependencyDirectory 'LibRaw-0.22.2\COPYRIGHT'), 'LibRaw-COPYRIGHT.txt'),
    @((Join-Path $DependencyDirectory 'Vulkan-Headers\LICENSE.md'), 'Vulkan-Headers-LICENSE.txt')
)
foreach ($copy in $copies) {
    if (-not (Test-Path -LiteralPath $copy[0] -PathType Leaf)) { throw "Missing licence file: $($copy[0])" }
    Copy-Item -LiteralPath $copy[0] -Destination (Join-Path $licenses $copy[1])
}
foreach ($noticeDir in @('codecs', 'input-codecs', 'lens')) {
    $source = Join-Path $BuildDirectory "engine\host\third-party\$noticeDir"
    if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Missing third-party notices: $source" }
    Copy-Item -Path (Join-Path $source '*') -Destination $licenses -Force
}
@'
SpektraLab and spektralab-host are free software under GPL-3.0-or-later.
The bundled profiles, LUTs, fonts, RAW/input codecs and lens-correction data
retain the licence and attribution files included in this directory.
'@ | Set-Content -LiteralPath (Join-Path $licenses 'README.txt') -Encoding UTF8

if (Test-Path -LiteralPath $StageDirectory) { Remove-Item -LiteralPath $StageDirectory -Recurse -Force }
Move-Item -LiteralPath $partial -Destination $StageDirectory
Write-Output "Staged Windows host: $StageDirectory"
