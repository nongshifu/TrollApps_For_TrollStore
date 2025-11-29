#import "SendMessage.h"

@implementation SendMessage

+ (void)sendRCIMTextMessageToUDID:(NSString *)targetUDID
                             messageText:(NSString *)messageText
                                 success:(void(^)(void))success
                                   error:(void(^)(NSString * errorMsg))error {
    // ------------ 1. 参数校验（使用融云官方错误码）------------
    // 目标UDID或消息文本为空 → 开发者传入参数错误（INVALID_PARAMETER: 33003）
    if (!targetUDID.length || !messageText.length) {
        if (error) error(@"目标UDID或消息文本为空");
        return;
    }
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:messageText];
    RCConversationType conversationType = ConversationType_PRIVATE;
    
    RCMessage *message = [[RCMessage alloc]
                          initWithType:conversationType
                          targetId:targetUDID
                          direction:MessageDirection_SEND
                          content:messageContent];
    
    
    [[RCIM sharedRCIM] sendMessage:message
                       pushContent:messageContent.content
                          pushData:messageContent.content
                      successBlock:^(RCMessage * _Nonnull successMessage) {
        if (successMessage) success();
        
    } errorBlock:^(RCErrorCode nErrorCode, RCMessage * _Nonnull errorMessage) {
        if (error) error([NSString stringWithFormat:@"%@",errorMessage]);
    }];
    
   
}

@end

