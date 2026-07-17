# Windows helper: prepare tree and remind to use WSL for real builds
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "Whyred Hybrid Kernel — Windows bootstrap" -ForegroundColor Cyan
Write-Host "Full kernel builds require WSL2 (Ubuntu) or a Linux host." -ForegroundColor Yellow

# Ensure directories
$dirs = @(
  ".src", "out", "out/dist", "out/modules",
  "arch/arm64/boot/dts/qcom", "configs/fragments",
  "patches/gki", "patches/sdm660", "patches/android",
  "drivers/whyred", "pack/AnyKernel3", "docs"
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}

Write-Host "Project tree OK under $Root"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. wsl --install   (if needed)"
Write-Host "  2. Open Ubuntu WSL, cd to this folder (e.g. /mnt/d/Kernel)"
Write-Host "  3. sed -i 's/\r$//' scripts/*.sh   # fix CRLF if needed"
Write-Host "  4. chmod +x scripts/*.sh"
Write-Host "  5. ./scripts/setup.sh"
Write-Host "  6. ./scripts/build.sh whyred"
