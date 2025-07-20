//
//  NewToolViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "DemoBaseViewController.h"
#import "WebToolModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface NewToolViewController : DemoBaseViewController
@property (nonatomic, strong, nullable) WebToolModel *editingTool;
// 当前操作类型
@property (nonatomic, assign) BOOL isUpdating;
@end

NS_ASSUME_NONNULL_END
