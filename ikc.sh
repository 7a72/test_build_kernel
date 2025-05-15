#!/bin/bash

ered() {
    echo -e "\033[31m" "$@" "\033[0m" >&2
}

egreen() {
    echo -e "\033[32m" "$@" "\033[0m"
}

ewhite() {
    echo -e "\033[37m" "$@" "\033[0m"
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 [on|off|eq] <CONFIG_NAME>[=VALUE] <kernel_config_file>"
    exit 1
fi

parse_config_arg() {
    local mode="$1"
    local arg="$2"

    if [[ "$mode" == "on" || "$mode" == "off" ]]; then
        CONFIG_NAME="$arg"
        VALUE=""
        return 0
    fi

    if [[ "$mode" == "eq" ]]; then
        if [[ "$arg" == *"="* ]]; then
            CONFIG_NAME="${arg%%=*}"
            VALUE="${arg#*=}"
        else
            ered "For 'eq' mode, value must be provided with CONFIG_NAME (e.g., CONFIG_NAME=VALUE)"
            exit 1
        fi
        return 0
    fi

    ered "Invalid mode: $mode"
    exit 1
}

MODE=$1
parse_config_arg "$MODE" "$2"
FILE=$3

[ -f "$FILE" ] || {
    ered "Config file $FILE does not exist"
    exit 1
}

config_on() {
    local config=$1
    local file=$2
    
    if grep -q "$config=y\|$config=m" "$file"; then
        egreen "$config is already enabled"
        return 0
    fi
    
    if grep -q "# $config is not set" "$file"; then
        # 替换未启用的配置
        sed -i "s/# $config is not set/$config=y/" "$file"
        egreen "Enabled $config"
        return 0
    fi
    
    echo "$config=y" >> "$file"
    egreen "Added and enabled $config"
}

config_off() {
    local config=$1
    local file=$2
    
    if ! grep -q "$config=y\|$config=m" "$file"; then
        egreen "$config is already disabled"
        return 0
    fi
    
    if grep -q "$config=" "$file"; then
        # 替换已启用的配置
        sed -i "s/$config=.*$/# $config is not set/" "$file"
        egreen "Disabled $config"
        return 0
    fi
    
    echo "# $config is not set" >> "$file"
    egreen "Added and disabled $config"
}

config_eq() {
    local config=$1
    local file=$2
    local value=$3
    
    escaped_value=$(printf '%q' "$value")
    
    if grep -q "^$config=$escaped_value" "$file"; then
        egreen "$config is already set to $value"
        return 0
    fi
    
    sed -i "/^$config=/d" "$file"
    
    echo "$config=$value" >> "$file"
    
    egreen "Set $config to $value"
}

case "$MODE" in
    on)
        config_on "$CONFIG_NAME" "$FILE"
        ;;
    off)
        config_off "$CONFIG_NAME" "$FILE"
        ;;
    eq)
        config_eq "$CONFIG_NAME" "$FILE" "$VALUE"
        ;;
    *)
        ered "Invalid mode. Use 'on', 'off', or 'eq'"
        exit 1
        ;;
esac
