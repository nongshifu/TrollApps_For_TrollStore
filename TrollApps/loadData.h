//
//  loadData.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UserModel.h"
#import "config.h"
#define SAVE_LOCAL_TAGS_KEY @"SAVE_LOCAL_TAGS_KEY"
#define SAVE_SERVER_TAGS_KEY @"SAVE_SERVER_TAGS_KEY"
NS_ASSUME_NONNULL_BEGIN

@interface loadData : NSObject
+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableArray<NSString *> *tags; // 标签按钮集合
@property (nonatomic, strong) UserModel *userModel; // 用户
//刷新融云
- (void)refreshUserInfoCache:(UserModel *)userModel;
@end

NS_ASSUME_NONNULL_END
