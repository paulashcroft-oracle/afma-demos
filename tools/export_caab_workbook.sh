#!/bin/zsh

set -eu

script_dir=${0:A:h}
repo_root=${script_dir:h}
source_arg=${1:-"${repo_root}/Data/caab_species_20260611.xls"}
csv_arg=${2:-"${repo_root}/.local/caab_species_20260611.csv"}
source_path=${source_arg:A}
csv_path=${csv_arg:A}

if [[ ! -f "$source_path" ]]; then
  print -u2 "Source workbook not found: $source_path"
  exit 2
fi

soffice_candidates=(
  "${HOME}/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice"
  "/Applications/LibreOffice.app/Contents/MacOS/soffice"
  "/opt/homebrew/bin/soffice"
  "/usr/local/bin/soffice"
)
soffice_path=""
for candidate in "${soffice_candidates[@]}"; do
  if [[ -x "$candidate" ]]; then
    soffice_path=$candidate
    break
  fi
done
if [[ -z "$soffice_path" ]]; then
  print -u2 "LibreOffice/soffice was not found. Load Codex Desktop workspace dependencies or install LibreOffice for macOS."
  exit 3
fi

/bin/mkdir -p "${csv_path:h}"
temp_dir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/afma-caab-export.XXXXXX")
generated_csv="${temp_dir}/${source_path:t:r}.csv"

"$soffice_path" \
  -env:UserInstallation="file://${temp_dir}/profile" \
  --headless \
  --convert-to 'csv:Text - txt - csv (StarCalc):44,34,76,1,1' \
  --outdir "$temp_dir" \
  "$source_path"

if [[ ! -s "$generated_csv" ]]; then
  print -u2 "LibreOffice did not create the expected CSV: $generated_csv"
  exit 4
fi

/bin/mv -f "$generated_csv" "$csv_path"
/bin/rmdir "$temp_dir" >/dev/null 2>&1 || true
/bin/ls -lh "$csv_path"
