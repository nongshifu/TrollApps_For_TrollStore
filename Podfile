# Uncomment the next line to define a global platform for your project
# platform :ios, '14.0'
#source 'https://github.com/CocoaPods/Specs.git'
# 强制所有 Pod 最低支持 iOS 12
platform :ios, '12.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 核心：把所有依赖库的最低版本改成 iOS 12
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      # 关闭老旧的 ARC 兼容
      config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
    end
  end
end
target 'TrollApps' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!


  # Pods for newTorllApps

  #pod 'AFNetworking'
  
  pod 'Masonry'
  pod 'BRPickerView' #地区国家区号选择器
  pod 'SVProgressHUD' #弹窗
  pod 'YYModel' #json转Model
  pod 'LGSideMenuController','2.3.0' #半屏控制器
  pod 'YYCache'
  pod 'JXCategoryView'  #标签选项
  pod 'FontAwesomeKit'
  pod 'SSZipArchive'

  

  
  pod 'IGListKit', '~> 5.0.0'#表格
  pod 'MJRefresh' #上下拉刷新


  pod 'ZXNavigationBar' #顶部导航控制器
  pod 'HWPanModal', '~> 0.9.4' #底部视图弹窗
  pod 'ZXingObjC' #二维码
  pod 'HXPhotoPickerObjC' #帖子照片展示
  pod 'HXPhotoPickerObjC/SDWebImage'
  pod "HXPhotoPickerObjC/SDWebImage_AF"
  pod 'RongCloudIM/IMKit' # 即时通讯基础 UI 组件


end
