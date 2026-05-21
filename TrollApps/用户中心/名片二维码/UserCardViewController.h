//
//  UserCardViewController.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/1/6.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "DemoBaseViewController.h"
#import <ZXingObjC/ZXingObjC.h>


NS_ASSUME_NONNULL_BEGIN

@interface UserCardViewController : DemoBaseViewController
@property (nonatomic, assign) int64_t userID; // 用户 ID
@property (nonatomic, strong) NSString *nickname; // 用户昵称
@property (nonatomic, strong) UIImage *avatarImage; // 用户头像
@end

NS_ASSUME_NONNULL_END
