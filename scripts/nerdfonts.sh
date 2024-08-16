#!/usr/bin/env bash

# exit on error
set -e

# http://nerdfonts.com/
fonts=("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/DejaVuSansMono.zip")

INSTALLED=no
for url in "${fonts[@]}"; do
  TARGETDIR=~/.fonts/$(basename $url .zip)
  if test -d ${TARGETDIR}; then
    echo "[-] Directory already exists ${TARGETDIR}"
  else
    echo "[+] Installing in [${TARGETDIR}]"
    echo "[+] Download font [$url]"
    wget -q --show-progress -P /tmp $url
    unzip -oq /tmp/$(basename $url) -d ${TARGETDIR}
    rm -f /tmp/$(basename $url)
    INSTALLED=si
  fi
done

if [ $INSTALLED = "si" ]; then
  # Load font cache
  echo "[+] Updating font cache"
  fc-cache -f
else
  echo "[-] No new font, no need to update font cache"
fi

# Finish message
echo "[+] Done!"

