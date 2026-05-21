//
//  CommunityViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/6/30.
//

#import <RongIMKit/RongIMKit.h>
#import <UIKit/UIKit.h>
#import "config.h"
#import "ToolMessage.h"

NS_ASSUME_NONNULL_BEGIN


@interface ChatListViewController : RCConversationListViewController
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
