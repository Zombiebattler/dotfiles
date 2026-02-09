#!/usr/bin/env bash

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -u
PATH=/usr/local/bin:/usr/bin:/bin

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
DOWNLOAD_DIR="/home/leon/Downloads"
ARCHIVE_DIR="$DOWNLOAD_DIR/Archive"

# --------------------------------------------------
# Immich Konfiguration
# --------------------------------------------------
IMMICH_URL="http://###.###.###.##:####"
IMMICH_API_KEY="<IMMICH_API_KEY"

MAX_SIZE=$((100 * 1024 * 1024)) # 100 MB

# --------------------------------------------------
# Kategorien
# --------------------------------------------------
declare -A CATEGORIES=(
  [videos]="mp4 mkv avi mov webm"
  [pictures]="jpg jpeg png gif bmp webp"
  [text]="txt pdf md doc docx odt"
  [piracy]="nzb torrent"
  [archives]="zip tar gz rar 7z"
  [iso]="iso"
  [audio]="mp3 wav flac ogg m4a"
)

# --------------------------------------------------
# Funktionen
# --------------------------------------------------
upload_to_immich() {
  local file="$1"

  curl -s -X POST "$IMMICH_URL/api/assets" \
    -H "x-api-key: $IMMICH_API_KEY" \
    -H "Accept: application/json" \
    -F "assetData=@$file" \
    -F "deviceAssetId=$(uuidgen)" \
    -F "deviceId=bash-script" \
    -F "fileCreatedAt=$(date -Iseconds)" \
    -F "fileModifiedAt=$(date -Iseconds)" \
    --fail
}

# --------------------------------------------------
# Vorbereitungen
# --------------------------------------------------
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR/other"

for category in "${!CATEGORIES[@]}"; do
  mkdir -p "$ARCHIVE_DIR/$category"
done

shopt -s nullglob

# --------------------------------------------------
# Dateien verarbeiten
# --------------------------------------------------
for file in "$DOWNLOAD_DIR"/*; do
  [[ -f "$file" ]] || continue

  filename="$(basename -- "$file")"
  extension="${filename##*.}"
  extension="${extension,,}"

  filesize=$(stat -c%s "$file")
  moved=false

  for category in "${!CATEGORIES[@]}"; do
    for ext in ${CATEGORIES[$category]}; do
      if [[ "$extension" == "$ext" ]]; then

        # 📸 Bilder & 🎥 Videos → Immich
        if [[ "$category" == "pictures" || "$category" == "videos" ]]; then
          if (( filesize <= MAX_SIZE )); then
            echo "⬆ Upload: $filename"

            if upload_to_immich "$file"; then
              mv "$file" "$ARCHIVE_DIR/$category/"
              echo "✅ Hochgeladen & verschoben"
            else
              echo "❌ Upload fehlgeschlagen: $filename"
            fi
          else
            echo "⛔ Zu groß (bleibt liegen): $filename"
          fi
        else
          mv "$file" "$ARCHIVE_DIR/$category/"
          echo "📁 Verschoben: $filename → $category"
        fi

        moved=true
        break 2
      fi
    done
  done

  # Sonstige Dateien
  if [[ "$moved" == false ]]; then
    mv "$file" "$ARCHIVE_DIR/other/"
    echo "📁 Verschoben: $filename → other"
  fi
done

echo "🧹 Download Cleanup abgeschlossen"

