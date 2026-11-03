param(
    [string]$Python = "$PSScriptRoot\..\.venv\Scripts\python.exe",
    [string]$Iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    [string]$Compiler = "C:\msys64\ucrt64\bin\g++.exe",
    [switch]$SkipRuntimeBuild
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path "$PSScriptRoot\..").Path

if (-not (Test-Path $Python)) {
    throw "Python executable not found: $Python"
}
if (-not (Test-Path $Iscc)) {
    throw "Inno Setup compiler not found: $Iscc"
}
if (-not (Test-Path $Compiler)) {
    throw "C++ compiler not found: $Compiler"
}

$PythonHome = (& $Python -c "import sys; print(sys.base_prefix)").Trim()
if (-not (Test-Path "$PythonHome\pythonw.exe")) {
    throw "Bundled Python home not found: $PythonHome"
}

$Bundle = Join-Path $Root "dist\SpektraStudioRuntime"
$Runtime = Join-Path $Bundle "runtime"
$SitePackages = Join-Path $Runtime "Lib\site-packages"

Push-Location $Root
try {
    if (-not $SkipRuntimeBuild) {
        if (Test-Path $Bundle) {
            Remove-Item $Bundle -Recurse -Force
        }
        New-Item $Bundle -ItemType Directory | Out-Null

        Write-Host "Copying embedded Python runtime..."
        & robocopy $PythonHome $Runtime /E /NFL /NDL /NJH /NJS /NP /XD "__pycache__" "include" "libs" "Scripts" "tcl" /XF "*.pyc"
        if ($LASTEXITCODE -ge 8) { throw "Python runtime copy failed with exit code $LASTEXITCODE" }

        New-Item $SitePackages -ItemType Directory -Force | Out-Null
        Write-Host "Copying application dependencies..."
        & robocopy "$Root\.venv\Lib\site-packages" $SitePackages /E /NFL /NDL /NJH /NJS /NP /XD "__pycache__" "tests" "test" "_tests" "PyInstaller" "_pytest" "pytest" /XF "*.pyc"
        if ($LASTEXITCODE -ge 8) { throw "Dependency copy failed with exit code $LASTEXITCODE" }

        foreach ($Package in @('spektrafilm', 'spektrafilm_gui', 'spektrafilm_lut_creator')) {
            $Destination = Join-Path $SitePackages $Package
            if (Test-Path $Destination) { Remove-Item $Destination -Recurse -Force }
            & robocopy "$Root\src\$Package" $Destination /E /NFL /NDL /NJH /NJS /NP /XD "__pycache__" "tests" /XF "*.pyc"
            if ($LASTEXITCODE -ge 8) { throw "Application package copy failed for $Package with exit code $LASTEXITCODE" }
        }

        Write-Host "Removing development-only files..."
        $DevelopmentDirectories = @(
            '__pycache__', 'tests', 'test', '_tests', 'htmlcov',
            'PyInstaller', '_pyinstaller_hooks_contrib', '_pytest', 'pytest',
            'debugpy', 'sphinx', 'alabaster'
        )
        Get-ChildItem $Runtime -Directory -Recurse -Force |
            Where-Object { $DevelopmentDirectories -contains $_.Name } |
            Sort-Object FullName -Descending |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem $Runtime -File -Recurse -Force -Include '*.pyc', '*.pyo' |
            Remove-Item -Force -ErrorAction SilentlyContinue

        Copy-Item LICENSE,SPEKTRAFILM_LICENSE.txt,CITATION.cff -Destination $Bundle

        Write-Host "Compiling native launcher..."
        & $Compiler -std=c++17 -O2 -static -static-libgcc -static-libstdc++ -municode -mwindows packaging/spektrastudio_launcher.cpp -o "$Bundle\SpektraStudio.exe"
        if ($LASTEXITCODE -ne 0) { throw "Launcher compilation failed with exit code $LASTEXITCODE" }

        Write-Host "Validating embedded runtime imports..."
        $env:QT_API = 'pyside6'
        $env:PYTHONNOUSERSITE = '1'
        & "$Runtime\python.exe" -c "from PySide6 import QtCore, QtGui, QtWidgets; import spektrafilm, spektrafilm_gui; print('Qt', QtCore.qVersion(), '- embedded runtime OK')"
        if ($LASTEXITCODE -ne 0) { throw "Embedded runtime validation failed with exit code $LASTEXITCODE" }
    }

    & $Iscc /Qp packaging/SpektraStudio.iss
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE" }

    Write-Host "Installer created at dist\installer\SpektraStudio-0.3.4-Windows-x64-Setup.exe"
}
finally {
    Pop-Location
}
