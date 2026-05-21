//
//  CategoryManagerViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//

#import "DemoBaseViewController.h"
#import "loadData.h"


NS_ASSUME_NONNULL_BEGIN

@interface CategoryManagerViewController : DemoBaseViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <NSString *>*titles; // 分类数组


@end

NS_ASSUME_NONNULL_END
