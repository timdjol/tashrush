#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
keystore_path="$project_root/android/app/upload-keystore.jks"
properties_path="$project_root/android/key.properties"
keytool_bin=${KEYTOOL_BIN:-keytool}

if [ -e "$keystore_path" ] || [ -e "$properties_path" ]; then
  echo "Signing files already exist; nothing was overwritten."
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is required to create a strong signing password."
  exit 1
fi

password=$(openssl rand -hex 24)
umask 077

"$keytool_bin" -genkeypair \
  -keystore "$keystore_path" \
  -storetype JKS \
  -storepass "$password" \
  -keypass "$password" \
  -alias tashrush-upload \
  -keyalg RSA \
  -keysize 4096 \
  -sigalg SHA256withRSA \
  -validity 10000 \
  -dname "CN=Tash Rush, OU=Mobile, O=Tash Rush, L=Bishkek, ST=Chuy, C=KG"

{
  printf 'storePassword=%s\n' "$password"
  printf 'keyPassword=%s\n' "$password"
  printf 'keyAlias=tashrush-upload\n'
  printf 'storeFile=upload-keystore.jks\n'
} > "$properties_path"

chmod 600 "$keystore_path" "$properties_path"
echo "Android upload key created. Back up android/app/upload-keystore.jks and android/key.properties."
