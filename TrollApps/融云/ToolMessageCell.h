//
//  ToolMessageCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/23.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <RongIMKit/RongIMKit.h>
#import "ToolMessage.h"
#import "AppInfoModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface ToolMessageCell : RCMessageCell


/*!
 消息的类型
 */
@property (nonatomic, assign) MessageForType messageForType;
/*!
 测试消息的帖子内容
 */
@property (nonatomic, strong) WebToolModel *webToolModel;
/*!
 测试消息的帖子内容
 */
@property (nonatomic, strong) AppInfoModel *appInfoModel;
/*!
 数据模型
 */
@property (nonatomic, strong) UserModel *userModel;
/*!
 文本内容的Label
*/
@property (strong, nonatomic) UILabel *ToolNameLabel;

/*!
 文本内容的Button
*/
@property (strong, nonatomic) UIButton *versionButton;

/*!
 文本内容的Label
*/
@property (strong, nonatomic) UILabel *ToolsuLabel;
/*!
 互动内容的Label
*/
@property (strong, nonatomic) UIImageView *avaImageView;

/*!
 根据消息内容获取显示的尺寸

 @param message 消息内容

 @return 显示的View尺寸
 */
+ (CGSize)getBubbleBackgroundViewSize:(ToolMessage *)message;

+ (NSString *)getObjectName;
@end

NS_ASSUME_NONNULL_END
