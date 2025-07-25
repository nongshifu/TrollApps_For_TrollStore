//
//  InjectionHistoryController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "InjectionRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface InjectionHistoryController : DemoBaseViewController<UITableViewDataSource, UITableViewDelegate>
- (void)refreshHistory; // 刷新历史记录
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<InjectionRecord *> *historyList; // 注入历史记录列表
@end

NS_ASSUME_NONNULL_END
