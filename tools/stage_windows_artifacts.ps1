# Stage CURRENT Windows build sources in the existing GitHub integration branch.
# This intentionally does not auto-push: FPGA/Vendor sources and BOOT.BIN must be reviewed in this PUBLIC repo.
param(
 [string]$VivadoXpr = "",
 [string]$WorkingCopy = "$env:USERPROFILE\Documents\FPGA_SpikeUlike_stage_20261116"
)
$ErrorActionPreference="Stop"
$repo="https://github.com/Ali-Hajiebrahim-Zargar/FPGA_SpikeUlike.git"
$branch="update/xu5-timestamp-v3-qt6-uart-off-20261116"
$ws="C:\vitis_timestamp_v3"
$cpp=Join-Path $env:USERPROFILE "Downloads\Mercury_XU5_CPP_Qt6_Realtime_v1\Mercury_XU5_CPP_Qt6_Realtime_v1"
$boot="C:\xu5\exports\SD_BOOT_TIMESTAMP_V3_UART_OFF_TEST_20261114_122558\BOOT.BIN"
$golden="C:\xu5\exports\SD_BOOT_SPIKE3371_20261023_172702\BOOT.BIN"
function AssertHash($path,$expected) {
 if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing file: $path"}
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected){throw "SHA256 mismatch: $path"}
}
function CopyFile($src,$dest) {
 if(!(Test-Path -LiteralPath $src -PathType Leaf)){throw "Missing source: $src"}
 $out=Join-Path $WorkingCopy $dest
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
 Copy-Item -LiteralPath $src -Destination $out -Force
 Write-Host "STAGED $dest"
}
if(!(Get-Command git.exe -ErrorAction SilentlyContinue)){throw "Install Git for Windows first."}
AssertHash $boot "B4AAB46FD459E4A9FB3A96BE7F6241C44B65090F999963F7367645BAF20C28CF"
AssertHash $golden "F7F923C492189299F45C1EDEDD88A4F769400B870209B16526C6765FCB7210AB"
if(Test-Path -LiteralPath $WorkingCopy){throw "WorkingCopy already exists. Supply a new -WorkingCopy path."}
& git.exe clone --branch $branch --single-branch $repo $WorkingCopy
if($LASTEXITCODE -ne 0){throw "Git clone failed"}

# Compiled and tested C++ Qt6 GUI: use the local fixed source rather than the unpatched ZIP.
$guiDest=Join-Path $WorkingCopy "GUI\cpp_qt6_realtime_v1"
if(!(Test-Path -LiteralPath (Join-Path $cpp "src\main.cpp"))){throw "C++ GUI source missing: $cpp"}
New-Item -ItemType Directory -Force -Path $guiDest | Out-Null
foreach($item in @("src","tests","reference","CMakeLists.txt","build-windows.ps1","README.md","VALIDATION.txt")){
 $src=Join-Path $cpp $item
 if(Test-Path -LiteralPath $src){Copy-Item -LiteralPath $src -Destination $guiDest -Recurse -Force}
}
$mainFile=Join-Path $guiDest "src\main.cpp"
$txt=[System.IO.File]::ReadAllText($mainFile)
$broken='const auto rx=state_.rx.load(),elapsed=clock_.elapsed();'
if($txt.Contains($broken)){
 $fixed="const auto rx = state_.rx.load();" + [Environment]::NewLine + "    const auto elapsed = clock_.elapsed();"
 $txt=$txt.Replace($broken,$fixed)
 [System.IO.File]::WriteAllText($mainFile,$txt,(New-Object System.Text.UTF8Encoding($false)))
}
$pythonGui=Join-Path $cpp "reference\python_gui_v4_original.py"
if(Test-Path -LiteralPath $pythonGui){CopyFile $pythonGui "GUI\ethernet_tc_tm_gui_v4.py"}

# Vitis current application source, BSP domain configuration and build API scripts.
$src=Join-Path $ws "lwip_echo_server\src"
if(!(Test-Path -LiteralPath $src -PathType Container)){throw "Vitis app source directory not found: $src"}
$vitisDest=Join-Path $WorkingCopy "Vitis\timestamp_v3_uart_off\lwip_echo_server"
New-Item -ItemType Directory -Force -Path $vitisDest | Out-Null
Copy-Item -LiteralPath $src -Destination $vitisDest -Recurse -Force
foreach($entry in @(
 @("lwip_echo_server\vitis-comp.json","Vitis\timestamp_v3_uart_off\lwip_echo_server\vitis-comp.json"),
 @("platform\platform-vitis-comp.json","Vitis\timestamp_v3_uart_off\platform-vitis-comp.json"),
 @("STEP228_build_platform.py","Vitis\timestamp_v3_uart_off\STEP228_build_platform.py"),
 @("STEP228_build_app.py","Vitis\timestamp_v3_uart_off\STEP228_build_app.py")
)){
 $f=Join-Path $ws $entry[0]
 if(Test-Path -LiteralPath $f){CopyFile $f $entry[1]}
}

# New BOOT.BIN in isolated path. Golden BOOT.BIN never copied or changed.
CopyFile $boot "Boot\TIMESTAMP_V3_UART_OFF_20261114\BOOT.BIN"
$bif="C:\xu5\exports\SD_BOOT_TIMESTAMP_V3_TEST_20261111\boot.bif"
if(Test-Path -LiteralPath $bif){CopyFile $bif "Boot\TIMESTAMP_V3_UART_OFF_20261114\original_windows_paths.bif"}

# Optional actual Vivado 2025.1 project Tcl and block-design Tcl export.
if($VivadoXpr){
 if(!(Test-Path -LiteralPath $VivadoXpr -PathType Leaf)){throw "Vivado XPR missing: $VivadoXpr"}
 $vivado="C:\Xilinx\2025.1\Vivado\bin\vivado.bat"
 $export=Join-Path $WorkingCopy "Vivado\export_current_project.tcl"
 $out=Join-Path $WorkingCopy "Vivado\current_timestamp_v3"
 New-Item -ItemType Directory -Force -Path $out | Out-Null
 & $vivado -mode batch -source $export -tclargs $VivadoXpr $out
 if($LASTEXITCODE -ne 0){throw "Vivado Tcl export failed. No commit or push performed."}
 # Archive can contain vendor IP. Keep out of this public GitHub commit.
 $archive=Join-Path $out "vivado_source_archive.zip"
 if(Test-Path -LiteralPath $archive){
  $keep=Join-Path $env:USERPROFILE "Documents\xu5_vivado_source_archive_review.zip"
  if(Test-Path -LiteralPath $keep){throw "Archive review destination already exists: $keep"}
  Move-Item -LiteralPath $archive -Destination $keep
  Write-Host "PRIVATE_REVIEW_ARCHIVE=$keep"
 }
}else{Write-Warning "Current Vivado .xpr unspecified; full current Tcl export pending."}

# Stage additions; do not modify original top-level GUI/Vivado/Vitis snapshot.
& git.exe -C $WorkingCopy add -- GUI/cpp_qt6_realtime_v1 GUI/ethernet_tc_tm_gui_v4.py Vitis/timestamp_v3_uart_off
if($LASTEXITCODE -ne 0){throw "Git source staging failed"}
if($VivadoXpr){& git.exe -C $WorkingCopy add -- Vivado/current_timestamp_v3}
& git.exe -C $WorkingCopy add -f -- Boot/TIMESTAMP_V3_UART_OFF_20261114/BOOT.BIN
& git.exe -C $WorkingCopy add -- Boot/TIMESTAMP_V3_UART_OFF_20261114/original_windows_paths.bif
Write-Host "===== STAGED CHANGES ====="
& git.exe -C $WorkingCopy diff --cached --stat
Write-Warning "PUBLIC repository: review licenses, secrets and compiled FPGA vendor IP before committing."
Write-Host "STAGING_ONLY=True"
Write-Host "WORKING_COPY=$WorkingCopy"
Write-Host "BRANCH=$branch"
Write-Host "Review then commit/push explicitly. No automatic publication of local files."
