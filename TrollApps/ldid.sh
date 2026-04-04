#!/bin/sh

#  idid.sh
#  TrollApps
#
#  Created by 十三哥 on 2026/4/2.
#  Copyright © 2026 iOS_阿玮. All rights reserved.
#CODE_SIGNING_ALLOWED=NO
#ENABLE_USER_SCRIPT_SANDBOXING=NO
#CODE_SIGN_ENTITLEMENTS = TrollApps/Root.entitlements

set -e

# ==============================================
# 🎯 核心配置
# ==============================================
SIGN_METHOD=2        # 0=原版ldid / 1=codesign / 2=脚本2完整签名(ldid+framework伪签名)

IPA_OUTPUT_DIR="/Users/shisange/Library/Mobile Documents/com~apple~CloudDocs/"
IPA_NAME="TrollApps.ipa"
LOG_FILE="$PROJECT_DIR/sign_auto_log.txt"
LDID_PATH="ldid"

# 加入脚本2必要PATH
export PATH="/opt/homebrew/bin:$PATH"

# ==============================================
# 📝 日志函数
# ==============================================
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

run_cmd() {
    local cmd="$*"
    log "----------------------------------------"
    log "执行命令：$cmd"
    eval "$cmd" 2>&1 | tee -a "$LOG_FILE"
    local ret=$?
    log "命令返回值：$ret"
    log "----------------------------------------"
    return $ret
}

# 清空日志
> "$LOG_FILE"

log "=============================================="
log " 🚀 Xcode 自动签名脚本 - $(date '+%Y-%m-%d %H:%M:%S')"
log " =============================================="

# ==============================================
# 环境路径
# ==============================================
APP_PATH="${CODESIGNING_FOLDER_PATH}"
PRODUCT_NAME="${EXECUTABLE_NAME}"
EXECUTABLE_PATH="${APP_PATH}/${PRODUCT_NAME}"

log "✅ APP 路径: $APP_PATH"
log "✅ 可执行文件: $EXECUTABLE_PATH"

# ==============================================
# ✅ 从 .app 内部读取权限文件
# ==============================================
ENTITLEMENTS_PATH="$APP_PATH/RootSign.entitlements"
log "✅ 权限文件（.app内）: $ENTITLEMENTS_PATH"

# 校验
if [ ! -f "$ENTITLEMENTS_PATH" ]; then log "❌ 权限文件不存在"; exit 1; fi
if [ ! -f "$EXECUTABLE_PATH" ]; then log "❌ 可执行文件不存在"; exit 1; fi
log "✅ 文件校验通过"

# ==============================================
# 预处理
# ==============================================
log "🔧 移除旧签名 + 修复权限"
run_cmd codesign --remove-signature "$EXECUTABLE_PATH"
run_cmd chmod -R 755 "$APP_PATH"
run_cmd chmod +x "$EXECUTABLE_PATH"

# ==============================================
# ✅ 签名模式：0 1 2
# ==============================================

# --------------------------
# SIGN_METHOD=0：原版 ldid
# --------------------------
if [ $SIGN_METHOD -eq 0 ]; then
    log ""
    log "=============================================="
    log " 📝 模式0：ldid 仅主程序签名（可复制命令）"
    log "=============================================="
    
    SIGN_CMD="'$LDID_PATH' -S'$ENTITLEMENTS_PATH' '$EXECUTABLE_PATH'"
    log "👉 $SIGN_CMD"
    log "=============================================="

    log "🚀 正在执行签名..."
    "$LDID_PATH" -S"$ENTITLEMENTS_PATH" "$EXECUTABLE_PATH" 2>&1 | tee -a "$LOG_FILE"
    LdidRet=$?

    if [ $LdidRet -ne 0 ]; then
        log "❌ 签名失败！错误码：$LdidRet"
        exit 1
    fi
    log "✅ ldid 主程序签名成功！"
fi

# --------------------------
# SIGN_METHOD=1：codesign
# --------------------------
if [ $SIGN_METHOD -eq 1 ]; then
    log "=============================================="
    log " 📝 模式1：codesign 签名"
    log "=============================================="
    run_cmd codesign -s - --entitlements "$ENTITLEMENTS_PATH" -f "$APP_PATH"
    log "✅ codesign 签名成功"
fi

# --------------------------
# SIGN_METHOD=2：脚本2完整逻辑（ldid主程序 + Frameworks伪签名）
# --------------------------
if [ $SIGN_METHOD -eq 2 ]; then
    log "=============================================="
    log " 📝 模式2：脚本2完整签名（ldid+framework伪签名）"
    log "=============================================="

    log "🚀 主程序 ldid 签名中..."
    "$LDID_PATH" -S"$ENTITLEMENTS_PATH" "$EXECUTABLE_PATH" 2>&1 | tee -a "$LOG_FILE"
    log "✅ 主程序 ldid 签名完成"

    # 签名 Frameworks
    FRAMEWORKS="${APP_PATH}/Frameworks"
    if [ -d "${FRAMEWORKS}" ]; then
        log "🔧 开始签名 Frameworks 框架（adhoc 伪签名）"
        find "${FRAMEWORKS}" -name "*.framework" -type d | while read -r fw; do
            bin="${fw}/$(basename ${fw} .framework)"
            if [ -f "${bin}" ]; then
                codesign -f -s "-" "${bin}" 2>&1 | tee -a "$LOG_FILE"
                log "✅ 已签名框架: $(basename ${bin})"
            fi
        done
    else
        log "ℹ️ 未找到 Frameworks 目录，跳过框架签名"
    fi

    log "🎉 模式2 全部签名完成！"
fi

# ==============================================
# 打包 IPA
# ==============================================
log "📦 打包 IPA..."
TMP_DIR="${CONFIGURATION_BUILD_DIR}/IPA_Temp"
run_cmd rm -rf "$TMP_DIR"
run_cmd mkdir -p "$TMP_DIR/Payload"
run_cmd cp -R "$APP_PATH" "$TMP_DIR/Payload/"

IPA_FULL_PATH="$IPA_OUTPUT_DIR/$IPA_NAME"
run_cmd mkdir -p "$IPA_OUTPUT_DIR"
cd "$TMP_DIR" && zip -q -r -X "$IPA_FULL_PATH" .

log "✅ IPA 输出: $IPA_FULL_PATH"
run_cmd rm -rf "$TMP_DIR"
log "🧹 清理完成"

log ""
log "=============================================="
log " 🎉 全部成功！"
log "==============================================\n"

exit 0
