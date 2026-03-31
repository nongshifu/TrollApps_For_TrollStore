
# .app路径
export appPath=$CODESIGNING_FOLDER_PATH

# entitlements路径
export entitlementsPath=$CODE_SIGN_ENTITLEMENTS
export newEntitlementsPath="$CONFIGURATION_BUILD_DIR/modified.entitlements"

# MachO文件的路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`

# Root签名
cp "$entitlementsPath" "$newEntitlementsPath"
codesign -s - --entitlements "${newEntitlementsPath}" -f "${appPath}"

# 给MachO文件上执行权限
#chmod 777 "${appPath}/$APP_BINARY"
#chmod u+s "${appPath}/$APP_BINARY"
#chown root:wheel "${appPath}/$APP_BINARY"
#chmod +x "${appPath}/$APP_BINARY"
