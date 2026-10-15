#!/usr/bin/env bash
#
# Bersihkan sisa build lama lalu bangun ulang aplikasi Kantin ITK.
#
# Build Android menyimpan banyak berkas antara. Sebagian ditimpa setiap
# build, tapi sebagian lagi menumpuk: distribusi Gradle versi lama, cache
# dependensi yang sudah tidak dipakai, dan berkas kerja daemon yang baru
# dilepas ketika daemonnya dihentikan. Script ini membereskan semuanya
# sebelum membangun, supaya ruang disk tidak habis di tengah jalan.
#
# Pemakaian:
#   ./tool/rebuild.sh                 bersihkan lalu build APK debug
#   ./tool/rebuild.sh --run           bersihkan, build, lalu pasang ke HP
#   ./tool/rebuild.sh --release       bangun APK release
#   ./tool/rebuild.sh --deep          ikut hapus berkas bersama Gradle
#   ./tool/rebuild.sh --no-build      hanya bersih-bersih, tanpa build
#
# --deep menyentuh cache Gradle yang dipakai bersama semua project di
# komputer ini, sehingga project lain ikut mengunduh ulang dependensinya
# (bisa 2-3 GB dan lama). Pakai hanya saat disk benar-benar sesak.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

DO_RUN=0
DO_BUILD=1
DEEP=0
BUILD_MODE="debug"

for arg in "$@"; do
  case "$arg" in
    --run)      DO_RUN=1 ;;
    --release)  BUILD_MODE="release" ;;
    --deep)     DEEP=1 ;;
    --no-build) DO_BUILD=0 ;;
    -h|--help)  sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Argumen tidak dikenal: $arg (pakai --help)"; exit 1 ;;
  esac
done

GRADLE_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

# ---------------------------------------------------------------------------
# Kunci agar hanya satu build berjalan pada satu waktu.
#
# Dua build Gradle yang menulis ke build/ bersamaan akan saling mengunci
# berkas cache Kotlin dan gagal dengan pesan "Could not delete ...
# caches-jvm". mkdir bersifat atomik, jadi cocok dipakai sebagai kunci.
# ---------------------------------------------------------------------------
LOCK="$PWD/.rebuild.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "Build lain sedang berjalan untuk project ini."
  echo "Tunggu sampai selesai, atau bila yakin tidak ada, hapus: $LOCK"
  exit 1
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

# Ruang kosong drive tempat project berada, dalam GB.
free_gb() {
  df -k . 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1024/1024}'
}

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }

BEFORE=$(free_gb)
step "Ruang disk sebelum dibersihkan: ${BEFORE} GB"

# ---------------------------------------------------------------------------
# 1. Hentikan daemon Gradle
#
# Daemon menahan berkas kerja sementara dan mengunci berkas di build/.
# Tanpa langkah ini, penghapusan berikutnya bisa gagal dan ruangnya tidak
# pernah kembali.
# ---------------------------------------------------------------------------
step "Menghentikan daemon Gradle dan Kotlin"
if [ -x ./android/gradlew ]; then
  (cd android && ./gradlew --stop 2>&1 | grep -Ei 'stopp|no gradle' || true)
else
  info "gradlew tidak ditemukan, dilewati"
fi

# Daemon Kotlin memetakan berkas cache ke memori dan tetap menahannya
# meski Gradle sudah berhenti. Inilah biang "Could not delete caches-jvm".
if command -v powershell.exe >/dev/null 2>&1; then
  killed=$(powershell.exe -NoProfile -Command "
    \$p = @(Get-CimInstance Win32_Process -Filter \"Name='java.exe'\" |
      Where-Object { \$_.CommandLine -match 'KotlinCompileDaemon' })
    \$p | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force -EA SilentlyContinue }
    \$p.Count" 2>/dev/null | tr -d '

 ')
  info "daemon Kotlin dihentikan: ${killed:-0}"
fi

# ---------------------------------------------------------------------------
# 2. Buang hasil build project
# ---------------------------------------------------------------------------
step "Membersihkan hasil build project"
flutter clean >/dev/null 2>&1 || true
rm -rf build .dart_tool android/.gradle android/app/build >/dev/null 2>&1
info "selesai"

# ---------------------------------------------------------------------------
# 3. Berkas bersama Gradle (hanya dengan --deep)
#
# Cache dan distribusi Gradle dipakai bersama oleh SEMUA project di komputer
# ini, bukan hanya Kantin ITK. Menghapusnya memaksa project lain mengunduh
# ulang dependensinya, jadi tidak dilakukan secara bawaan. Berkas yang
# sedang dipakai project lain juga terkunci dan akan dilewati.
# ---------------------------------------------------------------------------
if [ "$DEEP" -eq 1 ]; then
  step "Membersihkan berkas bersama Gradle (--deep)"
  info "project lain di komputer ini akan mengunduh ulang dependensinya"

  WRAPPER_PROPS="android/gradle/wrapper/gradle-wrapper.properties"
  DISTS="$GRADLE_HOME/wrapper/dists"
  if [ -f "$WRAPPER_PROPS" ] && [ -d "$DISTS" ]; then
    # Contoh isi: .../gradle-8.14.3-all.zip -> ambil "gradle-8.14.3-all"
    CURRENT=$(grep -o 'gradle-[0-9.]*-\(all\|bin\)' "$WRAPPER_PROPS" | head -1)
    info "versi yang dipakai project ini: ${CURRENT:-tidak terbaca}"
    if [ -n "$CURRENT" ]; then
      for d in "$DISTS"/*/; do
        name=$(basename "$d")
        [ "$name" = "$CURRENT" ] && continue
        if rm -rf "$d" 2>/dev/null && [ ! -d "$d" ]; then
          info "dihapus: $name"
        else
          rm -rf "$d" >/dev/null 2>&1
          info "dilewati (dipakai project lain): $name"
        fi
      done
    fi
  fi

  info "menghapus cache dependensi"
  rm -rf "$GRADLE_HOME/caches" >/dev/null 2>&1
else
  step "Berkas bersama Gradle dipertahankan"
  info "cache dan distribusi Gradle dipakai project lain juga"
  info "pakai --deep bila disk benar-benar sesak"
fi

AFTER=$(free_gb)
step "Ruang disk setelah dibersihkan: ${AFTER} GB"
info "dibebaskan sekitar $(awk -v a="$AFTER" -v b="$BEFORE" 'BEGIN{printf "%.1f", a-b}') GB"

if [ "$DO_BUILD" -eq 0 ]; then
  step "Selesai (tanpa build)"
  exit 0
fi

# ---------------------------------------------------------------------------
# 5. Ambil dependensi lalu bangun
# ---------------------------------------------------------------------------
step "Mengambil dependensi"
flutter pub get || exit 1

# Nilai konfigurasi (client ID Google, alamat API) disuntikkan dari berkas
# ini bila tersedia, agar tidak perlu diketik ulang setiap kali.
DEFINES=""
if [ -f config/dart_defines.json ]; then
  DEFINES="--dart-define-from-file=config/dart_defines.json"
  info "memakai config/dart_defines.json"
fi

if [ "$DO_RUN" -eq 1 ]; then
  step "Menjalankan aplikasi ke perangkat"
  exec flutter run $DEFINES --android-skip-build-dependency-validation
fi

step "Membangun APK ($BUILD_MODE)"
if ! flutter build apk --"$BUILD_MODE" $DEFINES --android-skip-build-dependency-validation; then
  echo
  echo "Build gagal. Bila pesannya soal ruang disk, jalankan:"
  echo "  ./tool/rebuild.sh --deep"
  exit 1
fi

APK="build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
step "Selesai"
[ -f "$APK" ] && info "APK: $APK ($(du -h "$APK" | cut -f1))"
info "Sisa disk: $(free_gb) GB"
