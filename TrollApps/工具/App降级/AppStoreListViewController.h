//
//  AppListViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2026/3/26.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "AppDowngradeModel.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                               format:(NSUInteger)format
                                                scale:(CGFloat)scale;
@end
@interface AppStoreListViewController : DemoBaseViewController

@end

NS_ASSUME_NONNULL_END
