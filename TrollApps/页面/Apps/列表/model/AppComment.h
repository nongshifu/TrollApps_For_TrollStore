//
//  AppComment.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "config.h"
#import "UserModel.h"
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

@interface AppComment : NSObject <IGListDiffable,YYModel>

@property (nonatomic, assign) NSInteger comment_id;
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy, nullable) NSString *user_udid;
@property (nonatomic, copy, nullable) NSString *idfv;
@property (nonatomic, strong) NSString *create_time;
@property (nonatomic, strong) NSString *update_time;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, assign) NSInteger like_count;
@property (nonatomic, strong) UserModel *userInfo;


@end

NS_ASSUME_NONNULL_END
