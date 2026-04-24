#!/usr/bin/env bash

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DOTS_DIR/manifest.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=0
if [[ "$1" == "-n" || "$1" == "--dry-run" ]]; then
  DRY_RUN=1
  echo -e "${YELLOW}[DRY RUN] Simulating operations. No files will be modified.${NC}"
  echo "-----------------------------------"
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo -e "${RED}Error: manifest.txt not found in $DOTS_DIR${NC}"
  exit 1
fi

echo -e "${BLUE}Syncing dotfiles from $DOTS_DIR...${NC}"
echo "-----------------------------------"

while IFS= read -r line || [[ -n "$line" ]]; do
  line=$(echo "$line" | xargs)

  # I skip empty lines and comments
  if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
    continue
  fi

  TARGET="$HOME/$line"
  REPO_FILE="$DOTS_DIR/$line"

  echo -e "Processing: ${YELLOW}$line${NC}"

  if [[ -L "$TARGET" ]]; then
    LINK_DEST=$(readlink "$TARGET")

    if [[ "$LINK_DEST" == *".mydotfiles"* ]]; then
      echo -e "  ${BLUE}[SKIP]${NC} Managed by ML4W. Ignoring."
      continue
    fi

    if [[ "$LINK_DEST" != "$REPO_FILE" ]]; then
      echo -e "  ${YELLOW}[CLEANUP]${NC} Removing invalid symlink."
      if [[ $DRY_RUN -eq 0 ]]; then rm "$TARGET"; fi
    else
      echo -e "  ${GREEN}[OK]${NC} Already linked."
      continue
    fi
  fi

  if [[ -f "$TARGET" && ! -L "$TARGET" ]]; then
    if [[ -f "$REPO_FILE" ]]; then
      echo -e "  ${YELLOW}[WARN]${NC} Conflict! System and Repo files exist. Backing up system file."
      if [[ $DRY_RUN -eq 0 ]]; then mv "$TARGET" "${TARGET}.bak"; fi
    else
      echo -e "  ${GREEN}[INGEST]${NC} Moving file to repository."
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$REPO_FILE")"
        mv "$TARGET" "$REPO_FILE"
      fi
    fi
  fi

  # If it exists in repo, or we are dry-running an ingestion
  if [[ -f "$REPO_FILE" || ($DRY_RUN -eq 1 && -f "$TARGET" && ! -L "$TARGET") ]]; then
    if [[ ! -L "$TARGET" ]]; then
      echo -e "  ${GREEN}[LINK]${NC} Creating symlink."
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$(dirname "$TARGET")"
        ln -s "$REPO_FILE" "$TARGET"
      fi
    fi
  else
    echo -e "  ${RED}[ERROR]${NC} File not found locally or in repo."
  fi

done <"$MANIFEST"

echo "-----------------------------------"
if [[ $DRY_RUN -eq 1 ]]; then
  echo -e "${YELLOW}Dry run complete!${NC}"
else
  echo -e "${GREEN}Sync complete!${NC}"
fi
