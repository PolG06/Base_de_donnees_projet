#!/bin/sh
printf '\033c\033]0;%s\a' Pointe ton Bagay
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Pointe-Ton-Bagay.x86_64" "$@"
