param(
    [string]$QtRoot = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $QtRoot) {
    $kits = @(Get-ChildItem "C:\Qt" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue } |
        Where-Object { $_.Name -eq "msvc2022_64" } |
        Sort-Object FullName -Descending)
    if ($kits.Count -gt 0) { $QtRoot = $kits[0].FullName }
}

if (-not $QtRoot -or -not (Test-Path (Join-Path $QtRoot "lib\cmake\Qt6\Qt6Config.cmake"))) {
    throw "Qt 6 MSVC2022 x64 was not found. Install Qt 6 Widgets + Network for MSVC2022_64, then run: .\build-windows.ps1 -QtRoot 'C:\Qt\6.x.x\msvc2022_64'"
}

$cmake = Get-Command cmake.exe -ErrorAction SilentlyContinue
if (-not $cmake) { throw "cmake.exe not found in PATH. Install CMake or use the Qt-provided build tools." }
$build = Join-Path $root "build"
& $cmake.Source -S $root -B $build -G "Visual Studio 17 2022" -A x64 "-DCMAKE_PREFIX_PATH=$QtRoot" -DXU5_BUILD_GUI=ON
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed. Check Visual Studio 2022 C++ tools and the Qt kit." }
& $cmake.Source --build $build --config Release --parallel
if ($LASTEXITCODE -ne 0) { throw "C++ compile failed." }
& $cmake.Source --build $build --config Release --target xu5_protocol_tests
if ($LASTEXITCODE -ne 0) { throw "Protocol test build failed." }
& ctest.exe --test-dir $build -C Release --output-on-failure
if ($LASTEXITCODE -ne 0) { throw "Protocol tests failed. Do not use the GUI for hardware testing yet." }
$exe = Join-Path $build "bin\Release\Mercury_XU5_GUI.exe"
if (-not (Test-Path $exe)) { throw "Expected executable missing: $exe" }
$deploy = Join-Path $QtRoot "bin\windeployqt.exe"
if (Test-Path $deploy) {
    & $deploy --release --dir (Split-Path -Parent $exe) $exe
    if ($LASTEXITCODE -ne 0) { Write-Warning "windeployqt failed; Qt runtime DLLs may be missing." }
} else {
    Write-Warning "windeployqt not found; ensure Qt DLLs are deployed before running."
}
Write-Host "BUILD_SUCCESS = True"
Write-Host "GUI_EXE = $exe"
Write-Host "Firmware/BOOT.BIN = NOT MODIFIED"
