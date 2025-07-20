//
//  ShowOneToolViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "WebToolModel.h"
#import "config.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowOneToolViewController : TemplateListController
@property (nonatomic, assign) NSInteger tool_id;
@property (nonatomic, strong) WebToolModel *webToolModel;
@end

NS_ASSUME_NONNULL_END
