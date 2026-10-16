#!/usr/bin/env bash
# KAEDE OS — Minimalist One-Liner Installer
set -euo pipefail

REPO="https://github.com/kaede-os/kaede-os"
INSTALL_DIR="${KAEDE_DIR:-$HOME/.kaede}"
BIN_DIR="${BUN_INSTALL:-$HOME/.bun}/bin"

echo ""
echo -e "  \033[35m╔══════════════════════════════════════╗\033[0m"
echo -e "  \033[35m║         KAEDE — CLI Installer        ║\033[0m"
echo -e "  \033[35m╚══════════════════════════════════════╝\033[0m"
echo ""

# 1. Ensure Bun runtime (auto-install if missing)
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$BIN_DIR:$PATH"

if ! command -v bun &>/dev/null; then
  if [ -x "$HOME/.bun/bin/bun" ]; then
    export PATH="$HOME/.bun/bin:$PATH"
  else
    echo -e "  \033[36m[1/3] Bun runtime tidak ditemukan. Menginstal Bun otomatis...\033[0m"
    if command -v curl &>/dev/null; then
      curl -fsSL https://bun.sh/install | bash
    elif command -v wget &>/dev/null; then
      wget -qO- https://bun.sh/install | bash
    else
      echo -e "  \033[31m✗ Memerlukan curl atau wget untuk menginstal Bun. Kunjungi https://bun.sh\033[0m"
      exit 1
    fi
    export PATH="$HOME/.bun/bin:$PATH"
  fi
fi

if ! command -v bun &>/dev/null; then
  echo -e "  \033[31m✗ Gagal menginisialisasi Bun. Silakan instal manual dari https://bun.sh\033[0m"
  exit 1
fi
echo -e "  \033[32m✓\033[0m Runtime: Bun $(bun --version)"

# 2. Clone or update repository from GitHub
echo -e "  \033[36m[2/3] Mengunduh KAEDE ke $INSTALL_DIR ...\033[0m"
if [ -d "$INSTALL_DIR/.git" ]; then
  cd "$INSTALL_DIR"
  git pull --rebase --quiet 2>/dev/null || true
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  if command -v git &>/dev/null; then
    git clone --depth 1 "$REPO" "$INSTALL_DIR" --quiet
  else
    mkdir -p "$INSTALL_DIR"
    curl -fsSL "$REPO/archive/main.tar.gz" | tar -xz --strip-components=1 -C "$INSTALL_DIR"
  fi
fi
echo -e "  \033[32m✓\033[0m Source: $REPO"

# 3. Create simple launcher wrapper in PATH
echo -e "  \033[36m[3/3] Menyiapkan perintah 'kaede'...\033[0m"
mkdir -p "$BIN_DIR"

LAUNCHER="$BIN_DIR/kaede"
cat <<'EOF' > "$LAUNCHER"
#!/usr/bin/env bash
KAEDE_DIR="${KAEDE_DIR:-$HOME/.kaede}"
BUN_BIN="$(command -v bun 2>/dev/null || echo "$HOME/.bun/bin/bun")"
exec "$BUN_BIN" "$KAEDE_DIR/scripts/kaede.ts" "$@"
EOF
chmod +x "$LAUNCHER"

echo -e "  \033[32m✓\033[0m Executable: $LAUNCHER"
echo ""
echo -e "  \033[32m\033[1m✅ KAEDE berhasil terpasang!\033[0m"
echo ""
echo -e "  Jalankan perintah berikut untuk memulai:"
echo -e "    \033[36mkaede --help\033[0m"
echo -e "    \033[36mkaede setup\033[0m"
echo ""

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  echo -e "  \033[33mTips: Tambahkan direktori berikut ke ~/.bashrc atau ~/.zshrc jika 'kaede' belum ditemukan:\033[0m"
  echo -e "    export PATH=\"$BIN_DIR:\$PATH\""
  echo ""
fi
