//
//  RCIM.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMKit/RongIMKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SendMessage : NSObject
/// 便捷发送消息函数（错误码统一使用融云官方定义）
/// @param targetUDID 对方的 UDID（原 self.toolModel.udid）
/// @param messageText 要发送的消息文本
/// @param success 两条消息都发送成功的回调
/// @param error 任意一条消息发送失败的回调（返回融云官方错误码）
+ (void)sendRCIMTextMessageToUDID:(NSString *)targetUDID
                             messageText:(NSString *)messageText
                                 success:(void(^)(void))success
                                   error:(void(^)(NSString * errorMsg))error;
@end

NS_ASSUME_NONNULL_END
