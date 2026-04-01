#!/bin/sh

#  idid.sh
#  TrollApps
#
#  Created by 十三哥 on 2026/4/2.
#  Copyright © 2026 iOS_阿玮. All rights reserved.
PATH="/opt/homebrew/bin:$PATH"
if [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
  ldid -S${CODE_SIGN_ENTITLEMENTS} ${CODESIGNING_FOLDER_PATH}
fi

#PATH="/opt/homebrew/bin:$PATH"
#
#if [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
#  echo "🚀 开始 ldid 全自动签名（主程序 + 所有框架）"
#
#  # 签名主程序
#  
#  ldid -S${CODE_SIGN_ENTITLEMENTS} "${CODESIGNING_FOLDER_PATH}"
#  echo "✅ 主程序签名完成"
#  
#
#  # 签名所有 frameworks
#  FRAMEWORKS="${CODESIGNING_FOLDER_PATH}/Frameworks"
#  if [ -d "${FRAMEWORKS}" ]; then
#    find "${FRAMEWORKS}" -name "*.framework" -type d | while read -r fw; do
#      bin="${fw}/$(basename ${fw} .framework)"
#      if [ -f "${bin}" ]; then
#        ldid -S${CODE_SIGN_ENTITLEMENTS} "${bin}"
#        echo "✅ 已签名框架: $(basename ${bin})"
#      fi
#    done
#  fi
#
#  echo "🎉 全部签名完成！"
#fi
