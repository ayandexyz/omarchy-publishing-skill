#!/usr/bin/env bash
# Local publishing-readiness preflight for an Omarchy plugin repository.
#
# Advisory only. This reproduces the marketplace's deterministic *structural*
# rules (scripts/build-catalog.mjs) plus heuristics for observed reviewer
# blockers. It is NOT the marketplace scanner and is NOT bot-authored evidence.
# A clean run here does not predict validation, security-baseline disposition,
# or maintainer approval.
#
# Usage: readiness-check.sh [--json] [PLUGIN_DIR]
# Exit:  0 = no blockers found   1 = blockers found   2 = could not run

set -uo pipefail

RULES_SOURCE="omacom/omarchy-plugin-marketplace scripts/build-catalog.mjs + security-baseline-policy.mjs"
RULES_CHECKED="2026-09-23"

JSON=0
DIR=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) DIR="$arg" ;;
  esac
done
DIR="${DIR:-$PWD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "readiness-check: jq is required but not installed." >&2
  exit 2
fi
if [ ! -d "$DIR" ]; then
  echo "readiness-check: not a directory: $DIR" >&2
  exit 2
fi
DIR="$(cd "$DIR" && pwd)"

BLOCKERS=(); WARNINGS=(); NOTES=(); CAPS=()
block() { BLOCKERS+=("$1"); }
warn()  { WARNINGS+=("$1"); }
note()  { NOTES+=("$1"); }
cap()   { case " ${CAPS[*]-} " in *" $1 "*) ;; *) CAPS+=("$1") ;; esac; }

# ---------------------------------------------------------------- file set
# Prefer git-tracked files: those are what the marketplace actually reads.
TRACKED=""
IS_GIT=0
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_GIT=1
  TRACKED="$(git -C "$DIR" ls-files 2>/dev/null)"
fi
if [ -n "$TRACKED" ]; then
  FILES="$TRACKED"
else
  FILES="$(cd "$DIR" && find . -path ./.git -prune -o -type f -print 2>/dev/null | sed 's|^\./||')"
  [ $IS_GIT -eq 1 ] && warn "Repository has no tracked files yet; checked the working tree instead. The marketplace only sees committed and pushed files."
fi
root_files() { printf '%s\n' "$FILES" | grep -v '/' || true; }
# Text files worth grepping, bounded so this stays fast on large trees.
scan_files() {
  printf '%s\n' "$FILES" \
    | grep -viE '\.(png|jpe?g|webp|avif|gif|ico|svg|pdf|zip|gz|xz|zst|tar|mp4|mp3|wav|ttf|otf|woff2?|so|a|o|bin|appimage)$' \
    | head -2000
}

# ---------------------------------------------------------------- manifest
MF="$DIR/manifest.json"
if [ ! -f "$MF" ]; then
  block "No root manifest.json. A new listing needs the root-plugin layout: one manifest.json at the repository root."
else
  if ! jq -e . "$MF" >/dev/null 2>&1; then
    block "manifest.json is not valid JSON."
  else
    m() { jq -r "$1 // empty" "$MF" 2>/dev/null; }

    [ "$(jq -r 'type' "$MF")" = "object" ] || block 'manifest.json must be a JSON object.'
    [ "$(jq -r '.schemaVersion|tostring' "$MF")" = "1" ] || block 'manifest "schemaVersion" must be exactly the number 1.'

    # required string fields, limits taken from manifestFieldLimits
    check_field() { # name limit
      local f="$1" lim="$2" v
      v="$(jq -r --arg f "$f" 'if (.[$f]|type)=="string" then .[$f] else empty end' "$MF")"
      if [ -z "$v" ] || [ -z "${v//[[:space:]]/}" ]; then
        block "manifest field \"$f\" is required and must be a non-empty string."
        return
      fi
      if printf '%s' "$v" | LC_ALL=C grep -qP '[\x00-\x1f\x7f-\x9f]' 2>/dev/null; then
        block "manifest field \"$f\" contains control characters."
      fi
      local trimmed="${v#"${v%%[![:space:]]*}"}"; trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
      if [ "$f" = "id" ] && [ "$v" != "$trimmed" ]; then
        block 'manifest field "id" must not have leading or trailing whitespace.'
      fi
      if [ "${#trimmed}" -gt "$lim" ]; then
        block "manifest field \"$f\" is ${#trimmed} characters; the community limit is $lim."
      fi
    }
    check_field id 128
    check_field name 120
    check_field version 64
    check_field author 120
    check_field description 500
    if jq -e 'has("license")' "$MF" >/dev/null 2>&1; then check_field license 120; fi

    ID="$(m .id)"
    if [ -n "$ID" ]; then
      if ! printf '%s' "$ID" | grep -qE '^[a-z0-9][a-z0-9._-]*$'; then
        block "manifest id \"$ID\" is invalid: community ids are lowercase and match ^[a-z0-9][a-z0-9._-]*\$."
      fi
      case "$ID" in
        *..*) block 'manifest id must not contain "..".' ;;
      esac
      case "$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')" in
        omarchy.*) block 'the "omarchy.*" id namespace is reserved for first-party plugins.' ;;
      esac
      case "$ID" in
        *.*) : ;;
        *) note "id \"$ID\" is not namespaced. A namespaced id (e.g. yourname.$ID) reduces collision risk; ids are permanent and retired ids are not reusable." ;;
      esac
    fi

    # kinds / entryPoints
    SUPPORTED="bar bar-widget menu overlay panel service"
    if [ "$(jq -r '.kinds|type' "$MF" 2>/dev/null)" != "array" ] || [ "$(jq -r '.kinds|length' "$MF")" -eq 0 ]; then
      block 'manifest "kinds" must be a non-empty array.'
    else
      while IFS= read -r k; do
        [ -z "$k" ] && continue
        case " $SUPPORTED " in
          *" $k "*) ;;
          *) block "unsupported kind \"$k\". Supported: $SUPPORTED." ; continue ;;
        esac
        key="$k"; [ "$k" = "bar-widget" ] && key="barWidget"
        if ! jq -e --arg key "$key" '.entryPoints | has($key)' "$MF" >/dev/null 2>&1; then
          block "kind \"$k\" declares no entry point; entryPoints.$key is missing."
        fi
      done < <(jq -r '.kinds[]? | select(type=="string")' "$MF")
    fi

    if [ "$(jq -r '.entryPoints|type' "$MF" 2>/dev/null)" != "object" ]; then
      block 'manifest "entryPoints" must be an object.'
    else
      [ "$(jq -r '.entryPoints|length' "$MF")" -eq 0 ] && block 'manifest "entryPoints" must not be empty.'
      while IFS= read -r ep; do
        [ -z "$ep" ] && continue
        case "$ep" in
          /*) block "entry point \"$ep\" must be relative, not absolute." ; continue ;;
          *..*) block "entry point \"$ep\" must not contain \"..\"." ; continue ;;
        esac
        if printf '%s' "$ep" | LC_ALL=C grep -qP '[\\:\r\n\x00]' 2>/dev/null; then
          block "entry point \"$ep\" contains a backslash, colon, newline or NUL."
          continue
        fi
        if [ ! -f "$DIR/$ep" ]; then
          block "declared entry point \"$ep\" does not exist in the repository."
        elif [ -n "$TRACKED" ] && ! printf '%s\n' "$TRACKED" | grep -qxF "$ep"; then
          block "entry point \"$ep\" exists locally but is not tracked by git; the marketplace will not see it."
        fi
      done < <(jq -r '.entryPoints // {} | to_entries[] | select(.value|type=="string") | .value' "$MF")
      jq -e '.entryPoints // {} | to_entries | map(select(.value|type!="string")) | length > 0' "$MF" >/dev/null 2>&1 \
        && block 'every entryPoints value must be a string.'
    fi

    if jq -e '.barWidget? | objects | has("defaultSection")' "$MF" >/dev/null 2>&1; then
      DS="$(jq -r '.barWidget.defaultSection // empty' "$MF")"
      case "$DS" in
        left|center|right) ;;
        *) block "barWidget.defaultSection must be left, center or right (found \"$DS\")." ;;
      esac
    fi
  fi
fi

# ------------------------------------------------------- required root docs
if ! root_files | grep -qiE '^readme(\.[^/]+)?$'; then
  block "No root README. A root README is required and must document installation and removal."
else
  RF="$(root_files | grep -iE '^readme(\.[^/]+)?$' | head -1)"
  if ! grep -qiE 'remov|uninstall|plugin remove' "$DIR/$RF" 2>/dev/null; then
    warn "README does not appear to document removal. The submission checklist requires installation *and* removal instructions."
  fi
fi
if ! root_files | grep -qiE '^(licen[cs]e|copying)(\.[^/]+)?$'; then
  block "No root license file. A LICENSE/LICENCE/COPYING file at the repository root is required; a manifest license field does not replace it."
fi

# ------------------------------------------------------------- tree hygiene
if [ $IS_GIT -eq 1 ]; then
  SYM="$(git -C "$DIR" ls-files -s 2>/dev/null | awk '$1=="120000"{print $4}')"
else
  SYM="$(cd "$DIR" && find . -path ./.git -prune -o -type l -print 2>/dev/null | sed 's|^\./||')"
fi
if [ -n "$SYM" ]; then
  block "Symlinks are not allowed in plugin folders: $(printf '%s' "$SYM" | tr '\n' ' ')"
fi

PREVIEWS="$(root_files | grep -iE '^preview\.(png|jpe?g|webp|avif)$' || true)"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  sz=$(stat -c %s "$DIR/$p" 2>/dev/null || echo 0)
  [ "$sz" -gt 52428800 ] && block "preview \"$p\" is $((sz/1048576)) MB; the limit is 50 MB (and 40 megapixels)."
done <<<"$PREVIEWS"
if [ -z "$PREVIEWS" ]; then
  BADP="$(root_files | grep -iE '^preview\.' || true)"
  [ -n "$BADP" ] && warn "Root preview \"$(printf '%s' "$BADP" | head -1)\" is not an accepted format (png, jpg, jpeg, webp, avif). Previews are optional."
fi

# Agent-control payload — an observed reviewer eligibility blocker.
AGENTFILES="$(printf '%s\n' "$FILES" | grep -iE '(^|/)(AGENTS\.md|CLAUDE\.md|GEMINI\.md|\.cursorrules)$|(^|/)\.(claude|cursor|agents|codex|opencode)/' || true)"
if [ -n "$AGENTFILES" ]; then
  block "Agent-control files ship inside the plugin payload ($(printf '%s' "$AGENTFILES" | paste -sd, -)) - reviewers have repeatedly required these be removed. Move contributor prose into ordinary docs under a non-auto-loaded name, and remove any agent hook/config installation from the payload."
fi

# --------------------------------------------- deterministic finding heuristics
# Mirrors the five securityBaselineRuleCatalog ids. Heuristic, not the scanner.
SCAN="$(scan_files)"
grep_scan() { # pattern -> "file:line: text"
  local pat="$1"
  printf '%s\n' "$SCAN" | while IFS= read -r f; do
    [ -f "$DIR/$f" ] || continue
    grep -nHiE "$pat" "$DIR/$f" 2>/dev/null | head -3 | sed "s|^$DIR/||"
  done | head -6
}
hit() { # id pattern message
  local out; out="$(grep_scan "$2")"
  [ -n "$out" ] && block "[$1] $3
    $(printf '%s' "$out" | sed 's/^/    /' | sed '1s/^ *//')"
}
hit curl-pipe-shell \
  '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|k)?sh' \
  "Downloaded content is piped straight into a shell. Remove the download-and-execute path; use a trusted package route or a verified immutable input."
hit cargo-git-unpinned \
  'cargo[[:space:]]+(install|build|add)[^\n]*--git' \
  "Cargo builds a Git source. This is a finding unless a full 40-character --rev is present on the same invocation; --locked does not pin the Git repository. Verify each hit."
hit sudoers-dangerous-passwordless-command \
  'NOPASSWD' \
  "A passwordless sudo rule is defined. Remove broad NOPASSWD command surfaces; a privileged helper needs a fixed, root-owned, strictly validated command boundary."
hit privileged-process-control-from-shared-temp \
  '/tmp/[^"'"'"'[:space:]]*(pid|lock)' \
  "PID or lock state appears to live in a shared temporary path. If a privileged signal is authorized from it, that is a blocking finding - move runtime state to \$XDG_RUNTIME_DIR and verify process identity immediately before signaling."
# An install instruction with no version pin, for software the plugin then
# executes. Not one of the five deterministic ids and not a blocker, but a
# repeatedly observed reviewer blocker: a floor like `pipx install foo` or
# `npm i -g bar` resolves the package AND its transitive dependencies to
# whatever is newest on the day, so the executable surface behind a reviewed
# commit changes with no change to the commit. Lines already carrying a pin,
# a hash, a lockfile or a digest are left alone.
UNPINNED_INSTALL="$(printf '%s\n' "$SCAN" | while IFS= read -r f; do
  [ -f "$DIR/$f" ] || continue
  grep -nHE '^[[:space:]]*[$>]?[[:space:]]*(sudo[[:space:]]+)?(pipx|pip3?|uv([[:space:]]+tool)?|npm|pnpm|yarn|cargo|go|gem|brew)[[:space:]]+(install|i|add)[[:space:]]' "$DIR/$f" 2>/dev/null \
    | grep -vE '==|--require-hashes|--rev[[:space:]]|@[0-9]|@sha256:|\.lock|requirements[^[:space:]]*\.txt|package-lock|Cargo\.lock|uv\.lock|poetry\.lock' \
    | head -3 | sed "s|^$DIR/||"
done | head -6)"
if [ -n "$UNPINNED_INSTALL" ]; then
  warn "Unpinned install instruction. If the plugin executes what this installs, expect a supply-chain finding: pin the complete dependency set to exact versions with verified hashes (a consumed lockfile, e.g. pip --require-hashes, npm ci, cargo --locked with a committed lock), not just the top-level package. Verify each hit - a documented command counts, a passing mention does not:
$(printf '%s' "$UNPINNED_INSTALL" | sed 's/^/    /')"
fi

# The other half of the same problem: a pinned install instruction is worth
# nothing if the plugin will auto-select a binary from somewhere else. Look for
# well-known unpinned install locations appearing as paths in code rather than
# docs - a candidate list, a discovery order, a fallback - because that is the
# plugin choosing on the user's behalf which unreviewed code gets to run.
DISCOVERY="$(printf '%s\n' "$SCAN" | grep -viE '(readme|changelog|contributing|security|license|docs?/|(^|/)tests?/|(^|/)spec/|[._-](test|spec)\.)' | while IFS= read -r f; do
  [ -f "$DIR/$f" ] || continue
  grep -nHE '(\.local/share/pipx/venvs|\.local/bin|\.cargo/bin|\.deno/bin|\.bun/bin|node_modules/\.bin|/usr/local/bin|/opt/homebrew/bin)' "$DIR/$f" 2>/dev/null \
    | head -3 | sed "s|^$DIR/||"
done | head -6)"
if [ -n "$DISCOVERY" ]; then
  warn "Executable discovered from an install location, in code. If the plugin picks any of these by itself, a pinned install instruction does not bind what actually runs - and an ownership or inode check does not either, since it binds a local file between check and execution, not the package versions behind it. Resolve one documented, pinned location; make anything else an explicit user setting:
$(printf '%s' "$DISCOVERY" | sed 's/^/    /')"
fi

# Code files only: docs mention these tools without passing data to them.
code_scan() { # pattern -> "file:line: text"
  local pat="$1"
  printf '%s\n' "$SCAN" | grep -viE '(readme|changelog|contributing|security|license|docs?/|(^|/)tests?/|(^|/)spec/|[._-](test|spec)\.|\.md$|\.d\.ts$|\.map$)' | while IFS= read -r f; do
    [ -f "$DIR/$f" ] || continue
    grep -nHE "$pat" "$DIR/$f" 2>/dev/null | head -3 | sed "s|^$DIR/||"
  done | head -6
}

# Process arguments are world-readable through /proc/<pid>/cmdline, so private
# content passed as argv is disclosed to other local users even with no shell.
ARGV_SINKS="$(code_scan '(notify-send|zenity|kdialog|dunstify|wl-copy|xclip)')"
if [ -n "$ARGV_SINKS" ]; then
  warn "A helper that takes its content as process arguments is called from code. Other local users can read any process's arguments through /proc/<pid>/cmdline, so private content (agent questions, commands, file paths, messages, titles) must not go into argv - send fixed text, or use stdin/D-Bus. An execFile/argv array prevents shell injection, not this. Fixed or non-private text is fine; check what each call actually passes:
$(printf '%s' "$ARGV_SINKS" | sed 's/^/    /')"
fi

# A client that discovers a loopback daemon through a connection file. When the
# daemon stops, the file can outlive it and the freed port is free for any
# local user, who then receives the token and payload and can forge replies.
LOOPBACK_CLIENT="$(code_scan '(port\.json|connection\.json|127\.0\.0\.1:|localhost:)')"
if [ -n "$LOOPBACK_CLIENT" ]; then
  warn "Code dials a loopback port, apparently from a connection file. Expect the reviewer to ask what happens when that file outlives the daemon: verify the connected peer's identity (e.g. its socket uid in /proc/net/tcp) before sending the token or private data, authenticate replies with a key that is never sent (HMAC over nonce, status and body), fail closed, and remove the file on shutdown. A bearer token alone authenticates the client, not the server. If this is already handled, say how in the maintainer notes:
$(printf '%s' "$LOOPBACK_CLIENT" | sed 's/^/    /')"
fi

# A pinned companion package is reviewed too: the maintainer audits its
# published archive and source, and a fix there needs a new release.
COMPANION="$(printf '%s\n' "$SCAN" | grep -iE '(readme|docs?/)' | while IFS= read -r f; do
  [ -f "$DIR/$f" ] || continue
  grep -nHE '(npm|pnpm|pipx|uv[[:space:]]+tool|cargo)[[:space:]]+(install|i|add)[[:space:]].*(@[0-9]|==[0-9]|--version[[:space:]])' "$DIR/$f" 2>/dev/null \
    | head -2 | sed "s|^$DIR/||"
done | head -3)"
if [ -n "$COMPANION" ]; then
  note "A pinned companion package is documented. Reviewers audit the published package at that pin (its archive and source), not only this repository, so run the review patterns over the companion too. A fix there means: publish a new version, bump the pin here, push, then edit the issue.
$(printf '%s' "$COMPANION" | sed 's/^/    /')"
fi

REMOTE_GIT="$(grep_scan 'git[[:space:]]+clone[^\n]*(--branch|--depth|https?://)')"
if [ -n "$REMOTE_GIT" ]; then
  warn "[remote-git-execution-unpinned] A remote Git source is cloned. If its code is then built or executed, bind it to a full 40-character commit and check out detached:
$(printf '%s' "$REMOTE_GIT" | sed 's/^/    /')"
fi

# ------------------------------------------------------- review capabilities
# Capabilities are not defects. They route the submission to manual review.
capcheck() { local out; out="$(grep_scan "$2")"; [ -n "$out" ] && cap "$1"; }
capcheck privilege '(^|[^[:alnum:]_])(sudo|pkexec)([^[:alnum:]_]|$)'
capcheck package-manager '(pacman|yay|paru|apt-get|apt|dnf|flatpak|pipx?|uv|npm|cargo)[[:space:]]+(-S|install|add|upgrade|update)'
capcheck service-management 'systemctl|loginctl|systemd-run'
capcheck sudoers-modification 'sudoers|visudo'
capcheck remote-build 'git[[:space:]]+clone|makepkg|cargo[[:space:]]+build|cmake|meson'
printf '%s\n' "$FILES" | grep -qiE '(^|/)(install|setup|bootstrap|uninstall|remove)[^/]*\.(sh|bash|py)$' && cap installer
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$DIR/$f" ] || continue
  if [ "$(head -c 4 "$DIR/$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]; then
    cap bundled-executable-binary
    warn "Bundled ELF binary: $f - the deterministic scan cannot inspect it, and it forces manual review. Ship source and build locally where possible."
  fi
done < <(printf '%s\n' "$FILES" | head -2000)

# ------------------------------------------------------------- publish state
SHA=""; BRANCH=""
if [ $IS_GIT -eq 1 ]; then
  SHA="$(git -C "$DIR" rev-parse HEAD 2>/dev/null)"
  BRANCH="$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
    block "Working tree has uncommitted changes. The marketplace only validates pushed commits; local-only fixes are not reviewable."
  fi
  UP="$(git -C "$DIR" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
  if [ -n "$UP" ]; then
    AHEAD="$(git -C "$DIR" rev-list --count "$UP..HEAD" 2>/dev/null || echo 0)"
    [ "${AHEAD:-0}" -gt 0 ] && block "HEAD is $AHEAD commit(s) ahead of $UP. Push before requesting validation; the reviewer scans the published default-branch HEAD."
    note "Upstream: $UP (comparison uses your last fetch; run 'git fetch' for a current answer)."
  else
    warn "No upstream tracking branch; could not compare local HEAD against the published branch."
  fi
  DEF="$(git -C "$DIR" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
  if [ -n "$DEF" ] && [ -n "$BRANCH" ] && [ "$BRANCH" != "$DEF" ]; then
    warn "You are on \"$BRANCH\" but the repository default branch is \"$DEF\". Validation reads the default branch."
  fi
else
  warn "Not a git repository; could not determine the commit SHA to submit."
fi

# ------------------------------------------------------------------- output
OUTCOME="ready-for-maintainer-review"
[ "${#BLOCKERS[@]}" -gt 0 ] && OUTCOME="blocked"

json_arr() { # preserves newlines inside each element
  if [ "$#" -eq 0 ]; then echo '[]'; else jq -n '$ARGS.positional' --args "$@"; fi
}

if [ "$JSON" -eq 1 ]; then
  jq -n \
    --arg dir "$DIR" --arg sha "$SHA" --arg branch "$BRANCH" \
    --arg outcome "$OUTCOME" --arg rules "$RULES_SOURCE" --arg checked "$RULES_CHECKED" \
    --argjson blockers "$(json_arr "${BLOCKERS[@]+"${BLOCKERS[@]}"}")" \
    --argjson warnings "$(json_arr "${WARNINGS[@]+"${WARNINGS[@]}"}")" \
    --argjson notes "$(json_arr "${NOTES[@]+"${NOTES[@]}"}")" \
    --argjson capabilities "$(json_arr "${CAPS[@]+"${CAPS[@]}"}")" \
    '{directory:$dir, commit:$sha, branch:$branch, localOutcome:$outcome,
      blockers:$blockers, warnings:$warnings, notes:$notes, reviewCapabilities:$capabilities,
      advisory:"Local heuristic preflight. Not the marketplace scanner and not bot-authored evidence.",
      rulesSource:$rules, rulesCheckedOn:$checked}'
else
  echo "Omarchy plugin readiness - $DIR"
  [ -n "$SHA" ] && echo "Commit: $SHA${BRANCH:+  (branch $BRANCH)}"
  echo
  if [ "${#BLOCKERS[@]}" -gt 0 ]; then
    echo "BLOCKERS (${#BLOCKERS[@]}) - fix before submitting:"
    for b in "${BLOCKERS[@]}"; do echo "  - $b"; done; echo
  fi
  if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo "WARNINGS (${#WARNINGS[@]}) - likely review questions:"
    for w in "${WARNINGS[@]}"; do echo "  - $w"; done; echo
  fi
  if [ "${#CAPS[@]}" -gt 0 ]; then
    echo "REVIEW CAPABILITIES detected: ${CAPS[*]}"
    echo "  These are not defects. They route the submission to manual maintainer review."
    echo "  Document each one honestly in maintainer notes and the README; hiding them is itself a blocker."
    echo
  fi
  if [ "${#NOTES[@]}" -gt 0 ]; then
    echo "NOTES:"
    for n in "${NOTES[@]}"; do echo "  - $n"; done; echo
  fi
  echo "Local outcome: $OUTCOME"
  echo
  echo "This is an advisory local preflight against structural rules from"
  echo "$RULES_SOURCE (checked $RULES_CHECKED)."
  echo "It does not run the marketplace security scanner, does not produce bot evidence,"
  echo "and does not predict approval. Re-read the live policy before submitting."
  echo "Deeper checks - secret handling, byte limits before buffering, path/identity"
  echo "safety, untrusted text sinks, dependency pinning - need the skill's audit pass."
fi

[ "${#BLOCKERS[@]}" -gt 0 ] && exit 1
exit 0
