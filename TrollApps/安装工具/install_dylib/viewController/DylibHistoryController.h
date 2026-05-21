//
//  DylibHistoryController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "CommandExecutor.h"
#import "DylibInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface DylibHistoryController : DemoBaseViewController<UITableViewDataSource, UITableViewDelegate>
- (void)refreshDylibList;

@property (nonatomic, copy) void(^onDylibSelected)(NSURL *dylibURL);

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<DylibInfo *> *dylibList; // 动态库列表
@property (nonatomic, strong) NSString *dylibStoragePath; // 动态库本地存储目录

@end

NS_ASSUME_NONNULL_END
