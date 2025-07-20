//
//  loadData.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UserModel.h"
#import "config.h"

NS_ASSUME_NONNULL_BEGIN

@interface loadData : NSObject
+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableArray<NSString *> *tags; // 标签按钮集合
@property (nonatomic, strong) UserModel *userModel; // 用户

@end

NS_ASSUME_NONNULL_END
