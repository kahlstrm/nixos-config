{ pkgs, lib, ... }:

pkgs.writeShellScriptBin "mdadm-telegram-notify" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Configuration file path from environment variable
    TELEGRAM_CONFIG_FILE=''${TELEGRAM_CONFIG_FILE:-/var/lib/secrets/telegram.env}

    if [[ ! -f "$TELEGRAM_CONFIG_FILE" ]]; then
      echo "Error: Telegram config file not found at $TELEGRAM_CONFIG_FILE" >&2
      exit 1
    fi

    # Source the config file to get TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID
    source "$TELEGRAM_CONFIG_FILE"

    if [[ -z "''${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "''${TELEGRAM_CHAT_ID:-}" ]]; then
      echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in $TELEGRAM_CONFIG_FILE" >&2
      exit 1
    fi

    # Get hostname
    HOSTNAME=$(${pkgs.nettools}/bin/hostname)

    # mdadm passes the event type and device as arguments
    EVENT="$1"
    DEVICE="''${2:-unknown}"

    # Build message based on event type
    case "$EVENT" in
      "Fail"|"FailSpare"|"SpareActive")
        MESSAGE="🚨 RAID Alert - $HOSTNAME: $EVENT on $DEVICE"
        ;;
      "NewArray"|"RebuildStarted"|"RebuildFinished")
        MESSAGE="ℹ️ RAID Info - $HOSTNAME: $EVENT on $DEVICE"
        ;;
      "DegradedArray"|"SparesMissing")
        MESSAGE="⚠️ RAID Warning - $HOSTNAME: $EVENT on $DEVICE"
        ;;
      *)
        MESSAGE="📡 RAID Event - $HOSTNAME: $EVENT on $DEVICE"
        ;;
    esac

    # Add timestamp and additional info
    TIMESTAMP=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')
    FULL_MESSAGE="$MESSAGE at $TIMESTAMP"

    # Get array status if device is specified
    if [[ "$DEVICE" != "unknown" ]] && [[ -e "$DEVICE" ]]; then
      ARRAY_STATUS=$(${pkgs.mdadm}/bin/mdadm --detail "$DEVICE" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E "(State|Active Devices|Failed Devices)" || echo "Status unavailable")
      FULL_MESSAGE="$FULL_MESSAGE

  Array Details:
  $ARRAY_STATUS"
    fi

    # Send to Telegram
    ${pkgs.curl}/bin/curl -s -X POST \
      "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d "chat_id=$TELEGRAM_CHAT_ID" \
      -d "text=$FULL_MESSAGE" \
      -d "parse_mode=HTML" \
      > /dev/null

    echo "Notification sent to Telegram"
''
