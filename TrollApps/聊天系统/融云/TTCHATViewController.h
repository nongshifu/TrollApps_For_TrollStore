//
//  TTCHATViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <RongIMKit/RongIMKit.h>
#import "Config.h"
#import "UserModel.h"
#import "ToolMessage.h"

NS_ASSUME_NONNULL_BEGIN



typedef NS_ENUM(NSUInteger, ChatInitiationType) {
    /// 默认
    ChatInitiationTypeDefault,
    /// 社区广场发起聊天
    ChatInitiationTypeCommunitySquare,
    /// 首页漂流瓶发起聊天
    ChatInitiationTypeHomePageDriftBottle,
    /// 地图界面发起聊天
    ChatInitiationTypeMap,
    /// 用户个人资料页发起聊天
    ChatInitiationTypeUserProfile,
    /// 搜索结果页发起聊天
    ChatInitiationTypeSearchResult,
    /// 群组列表页发起聊天
    ChatInitiationTypeGroupList,
    /// 通知消息页发起聊天
    ChatInitiationTypeNotification,
    /// 社区推荐
    ChatInitiationTypeCommunityRecommend,
};

@interface TTCHATViewController : RCConversationViewController<HWPanModalPresentable>
@property (nonatomic, strong) RCMessageContent *message;
@property (nonatomic, strong) UserModel *user;
//搜索关键字
@property (nonatomic, strong) NSString *keyword;

/*!
 数据模型
 */
@property (nonatomic, strong) id shareModel;
/*!
 是否为分享状态
 */
@property (nonatomic, assign) BOOL isShare;


/*!
 消息的类型
 */
@property (nonatomic, assign) MessageForType messageForType;



@end

NS_ASSUME_NONNULL_END
