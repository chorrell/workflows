#!/usr/bin/env bash
# Fixture for the shell-lint self-test in ci.yml: must pass shellcheck and shfmt.
set -euo pipefail

greet() {
  local name="$1"
  echo "Hello, ${name}" > /dev/null
}

greet "${1:-world}"
