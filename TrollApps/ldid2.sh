#!/bin/sh
set -e

# ==============================================
# 🎯 核心配置
# ==============================================
SIGN_METHOD=0
IPA_OUTPUT_DIR="/Users/shisange/Library/Mobile Documents/com~apple~CloudDocs/"
IPA_NAME="TrollApps.ipa"
LOG_FILE="$PROJECT_DIR/sign_auto_log.txt"
LDID_PATH="ldid"

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
# ✅ ldid 签名 + 输出完整命令到日志（可直接复制）
# ==============================================
if [ $SIGN_METHOD -eq 0 ]; then
    log ""
    log "=============================================="
    log " 📝 最终签名命令（可直接复制到终端执行）"
    log "=============================================="
    
    # 拼接完整签名命令（带引号，解决空格问题）
    SIGN_CMD="'$LDID_PATH' -S'$ENTITLEMENTS_PATH' '$EXECUTABLE_PATH'"
    log "👉 $SIGN_CMD"
    log "=============================================="
    log ""

    # 执行签名
    log "🚀 正在执行签名..."
    "$LDID_PATH" -S"$ENTITLEMENTS_PATH" "$EXECUTABLE_PATH" 2>&1 | tee -a "$LOG_FILE"
    LdidRet=$?

    if [ $LdidRet -ne 0 ]; then
        log "❌ 签名失败！错误码：$LdidRet"
        exit 1
    fi
    log "✅ ldid 签名成功！"
fi

# ==============================================
# codesign 备用
# ==============================================
if [ $SIGN_METHOD -eq 1 ]; then
    log "📝 codesign 签名"
    run_cmd codesign -s - --entitlements "$ENTITLEMENTS_PATH" -f "$APP_PATH"
    log "✅ codesign 签名成功"
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
