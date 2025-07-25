//
//  BottomSheetTransition.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BottomSheetTransition : NSObject<UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) BOOL isPresenting;
@end

NS_ASSUME_NONNULL_END
