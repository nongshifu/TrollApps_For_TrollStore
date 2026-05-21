//
//  moodStatusModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface MoodStatusModel : NSObject<IGListDiffable, YYModel>
//对应自增iD
@property (nonatomic, assign) NSInteger mood_id;
//对应udid
@property (nonatomic, copy) NSString *user_udid;
/// 发布内容
@property (nonatomic, copy) NSString *content;
/// 发布时间（格式建议：@"2025-10-21 15:30:00"）
@property (nonatomic, copy) NSString *publish_time;


@end

NS_ASSUME_NONNULL_END
