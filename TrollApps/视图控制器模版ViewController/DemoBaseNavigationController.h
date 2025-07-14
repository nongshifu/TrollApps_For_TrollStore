//
//  DemoBaseNavigationController.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/23.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <ZXNavigationBar/ZXNavigationBar.h>
#import "ZXNavigationBarController.h"
NS_ASSUME_NONNULL_BEGIN

@interface DemoBaseNavigationController : ZXNavigationBarNavigationController
- (void)setAllowEdgeInteractive:(BOOL)allowEdgeInteractive;
@end

NS_ASSUME_NONNULL_END
