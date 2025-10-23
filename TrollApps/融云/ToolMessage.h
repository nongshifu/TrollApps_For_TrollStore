//
//  ToolMessage.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/23.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <RongIMLibCore/RongIMLibCore.h>
#import "WebToolModel.h"
NS_ASSUME_NONNULL_BEGIN

/*!
 测试消息的类型名
 */
#define RCDPostMessageTypeIdentifier @"RCD:ToolMsg"

@interface ToolMessage : RCMessageContent<NSCoding>
/*!
 测试消息的帖子内容
 */
@property (nonatomic, strong) WebToolModel *webToolModel;
/*!
 测试消息的内容
 */
@property (nonatomic, strong) NSString *content;

/*!
 初始化测试消息

 @param content 文本内容
 @return        测试消息对象
 */
+ (instancetype)messageWithContent:(NSString *)content;


+ (NSString *)getObjectName;
@end

NS_ASSUME_NONNULL_END
