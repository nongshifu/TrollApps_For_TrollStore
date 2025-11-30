//
//  ToolMessage.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/23.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "ToolMessage.h"



@implementation ToolMessage

///初始化
+ (instancetype)messageWithContent:(NSString *)content {
    NSLog(@"开始执行 messageWithContent 方法，传入的内容为: %@", content);
    ToolMessage *toolMessage = [[ToolMessage alloc] init];
    if (toolMessage) {
        toolMessage.content = content;
        NSLog(@"成功初始化 RCDPostMessage 对象，内容设置为: %@", toolMessage.content);
    } else {
        NSLog(@"RCDPostMessage 对象初始化失败");
    }
    return toolMessage;
}

///消息是否存储，是否计入未读数
+ (RCMessagePersistent)persistentFlag {
    NSLog(@"执行 persistentFlag 方法，返回存储和计数标志");
    return (MessagePersistent_ISPERSISTED | MessagePersistent_ISCOUNTED);
}

/// NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"开始执行 initWithCoder 方法，解码器对象: %@", aDecoder);
    self = [super init];
    if (self) {
        
        self.content = [aDecoder decodeObjectForKey:@"content"];
        NSLog(@"从解码器中解码 content 字段，值为: %@", self.content);
        self.extra = [aDecoder decodeObjectForKey:@"extra"];
        NSLog(@"从解码器中解码 extra 字段，值为: %@", self.extra);
        //解密帖子数据
        NSDictionary *data = [self.extra yy_modelToJSONObject];
        NSLog(@"从解码器中解码 data 字段，值为: %@", data);
        if(self.messageForType == MessageForTypeTool || data[@"tool_id"]){
            self.webToolModel = [WebToolModel yy_modelWithDictionary:data];
        }else if(self.messageForType == MessageForTypeApp || data[@"app_id"]){
            self.appInfoModel = [AppInfoModel yy_modelWithDictionary:data];
        }else if(self.messageForType == MessageForTypeUser || data[@"nickname"]){
            self.userModel = [UserModel yy_modelWithDictionary:data];
        }
        
    } else {
        NSLog(@"父类初始化失败");
    }
    return self;
}

/// NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.content forKey:@"content"];
    NSLog(@"将 content 字段编码到编码器，值为: %@", self.content);
    [aCoder encodeObject:self.extra forKey:@"extra"];
   
}

///将消息内容编码成json
- (NSData *)encode {
    NSLog(@"开始执行 encode 方法，准备将消息内容编码为 JSON");
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:self.content forKey:@"content"];
    NSLog(@"将 content 字段添加到字典，值为: %@", self.content);
    
    if (self.extra) {
        [dataDict setObject:self.extra forKey:@"extra"];
        NSLog(@"将 extra 字段添加到字典，值为: %@", self.extra);
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
    if (data) {
        NSLog(@"成功将字典转换为 NSData 对象，数据长度: %lu", (unsigned long)data.length);
    } else {
        NSLog(@"将字典转换为 NSData 对象失败");
    }
    return data;
}

/// 将json解码生成消息内容
- (void)decodeWithData:(NSData *)data {
    NSLog(@"开始执行 decodeWithData 方法，传入的 NSData 对象长度: %lu", (unsigned long)data.length);
    if (!data) {
        NSLog(@"传入的 NSData 对象为空");
        return;
    }

    // 1. 先将传入的 data 转成根字典（这一步是对的）
    __autoreleasing NSError *rootError = nil;
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:&rootError];
    if (!rootDict) {
        NSLog(@"根数据转字典失败，错误: %@", rootError.localizedDescription);
        return;
    }

    // 2. 解析根字典中的基础字段（content/extra）
    self.content = rootDict[@"content"] ?: @"";
    NSLog(@"从根字典获取 content: %@", self.content);
    
    // 关键修正：self.extra 是 JSON 字符串，需先转成字典
    self.extra = rootDict[@"extra"] ?: @"";
    NSLog(@"从根字典获取 extra（JSON字符串）: %@", self.extra);
    if (![self.extra isKindOfClass:[NSString class]] || self.extra.length == 0) {
        NSLog(@"extra 不是有效字符串，无法解析 webToolModel");
        
        return;
    }

    // 3. 将 extra（JSON字符串）转成 NSData
    NSData *extraData = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (!extraData) {
        NSLog(@"extra 字符串转 NSData 失败（编码错误）");
        
        return;
    }

    // 4. 将 extraData 转成 extra 字典（这是之前缺失的步骤）
    __autoreleasing NSError *extraError = nil;
    NSDictionary *extraDict = [NSJSONSerialization JSONObjectWithData:extraData
                                                               options:kNilOptions
                                                                 error:&extraError];
    if (!extraDict) {
        NSLog(@"extraData 转字典失败，错误: %@", extraError.localizedDescription);
        
        return;
    }
    NSLog(@"消息类型:%ld  extra 字符串解析成字典: %@ ", self.messageForType, extraDict);
    NSLog(@"tool_id:%@  app_id:%@",extraDict[@"tool_id"],extraDict[@"app_id"]);
    if(extraDict[@"tool_id"] && [extraDict[@"tool_id"] intValue] >0){
        NSLog(@"是工具");
        self.messageForType = MessageForTypeTool;
        self.webToolModel = [WebToolModel yy_modelWithDictionary:extraDict];
    }else if(extraDict[@"app_id"] && [extraDict[@"app_id"] intValue] >0){
        NSLog(@"是软件");
        self.messageForType = MessageForTypeApp;
        self.appInfoModel = [AppInfoModel yy_modelWithDictionary:extraDict];
    }else if(extraDict[@"nickname"] && [extraDict[@"user_id"] intValue] >0){
        NSLog(@"是用户");
        self.messageForType = MessageForTypeUser;
        self.userModel = [UserModel yy_modelWithDictionary:extraDict];
    }
    
    
}

/// 会话列表中显示的摘要
- (NSString *)conversationDigest {
    NSLog(@"执行 conversationDigest 方法，返回摘要内容: %@", self.content);
    return self.content;
}

///消息的类型名
+ (NSString *)getObjectName {
    NSLog(@"执行 getObjectName 方法，返回消息类型名: %@", RCDPostMessageTypeIdentifier);
    return RCDPostMessageTypeIdentifier;
}


@end
