//
//  MyCollectionViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.

//

#import "DemoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MyCollectionViewController : DemoBaseViewController
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL showFollowList;//是否显示关注列表
@property (nonatomic, strong) NSString *target_udid;//查询目标
@end

NS_ASSUME_NONNULL_END
