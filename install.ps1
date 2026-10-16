# KAEDE OS — Minimalist One-Liner Installer for Windows PowerShell
$ErrorActionPreference = 'Stop'

$Repo = 'https://github.com/kaede-os/kaede-os'
$InstallDir = if ($env:KAEDE_DIR) { $env:KAEDE_DIR } else { "$HOME\.kaede" }
$BinDir = "$HOME\.bun\bin"

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║         KAEDE — CLI Installer        ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# 1. Ensure Bun runtime (auto-install if missing)
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  if (Test-Path "$BinDir\bun.exe") {
    $env:PATH = "$BinDir;$env:PATH"
  } else {
    Write-Host "  [1/3] Bun runtime tidak ditemukan. Menginstal Bun otomatis..." -ForegroundColor Cyan
    try {
      powershell -c "irm bun.sh/install.ps1 | iex"
      $env:PATH = "$BinDir;$env:PATH"
    } catch {
      Write-Host "  ✗ Gagal menginstal Bun otomatis. Silakan unduh manual dari https://bun.sh" -ForegroundColor Red
      exit 1
    }
  }
}

if (Get-Command bun -ErrorAction SilentlyContinue) {
  Write-Host "  ✓ Runtime: Bun $(bun --version)" -ForegroundColor Green
} else {
  Write-Host "  ✗ Bun runtime belum terdeteksi. Silakan pasang dari https://bun.sh" -ForegroundColor Yellow
  exit 1
}

# 2. Clone or update repository from GitHub
Write-Host "  [2/3] Mengunduh KAEDE ke $InstallDir ..." -ForegroundColor Cyan
if (Test-Path "$InstallDir\.git") {
  Push-Location $InstallDir
  try { git pull --rebase --quiet } catch {}
  Pop-Location
} else {
  if (-not (Test-Path (Split-Path $InstallDir))) {
    New-Item -ItemType Directory -Path (Split-Path $InstallDir) -Force | Out-Null
  }
  if (Get-Command git -ErrorAction SilentlyContinue) {
    git clone --depth 1 $Repo $InstallDir --quiet
  } else {
    Invoke-WebRequest -Uri "$Repo/archive/main.zip" -OutFile "$HOME\kaede.zip"
    Expand-Archive "$HOME\kaede.zip" -DestinationPath "$HOME\kaede_temp" -Force
    Move-Item "$HOME\kaede_temp\kaede-os-main" $InstallDir -Force
    Remove-Item "$HOME\kaede.zip", "$HOME\kaede_temp" -Recurse -Force
  }
}
Write-Host "  ✓ Source: $Repo" -ForegroundColor Green

# 3. Create simple CMD and PS1 launcher wrappers
Write-Host "  [3/3] Menyiapkan perintah 'kaede'..." -ForegroundColor Cyan
if (-not (Test-Path $BinDir)) {
  New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$CmdLauncher = "$BinDir\kaede.cmd"
"@echo off`nbun `"%USERPROFILE%\.kaede\scripts\kaede.ts`" %*" | Out-File -FilePath $CmdLauncher -Encoding ascii -Force

$Ps1Launcher = "$BinDir\kaede.ps1"
"& bun `"`$env:USERPROFILE\.kaede\scripts\kaede.ts`" `$args" | Out-File -FilePath $Ps1Launcher -Encoding utf8 -Force

Write-Host "  ✓ Executable: $CmdLauncher" -ForegroundColor Green
Write-Host ""
Write-Host "  ✅ KAEDE berhasil terpasang!" -ForegroundColor Green
Write-Host ""
Write-Host "  Jalankan perintah berikut untuk memulai:"
Write-Host "    kaede --help" -ForegroundColor Cyan
Write-Host "    kaede setup" -ForegroundColor Cyan
Write-Host ""
