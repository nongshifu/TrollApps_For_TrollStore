//
//  AppSearchViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "DemoBaseViewController.h"
#import "ITunesAppModel.h"
#import "config.h"
NS_ASSUME_NONNULL_BEGIN

@class AppSearchViewController;
@protocol AppSearchViewControllerDelegate <NSObject>
// 点击单元格时回调选中的应用信息
- (void)didSelectAppModel:(ITunesAppModel *)model controller:(AppSearchViewController*)controller tableView:(UITableView*)tableView cell:(UITableViewCell*)cell;
@end

@interface AppSearchViewController : DemoBaseViewController
@property (nonatomic, weak) id<AppSearchViewControllerDelegate> delegate;
@property (nonatomic, strong)  NSString *keyword;
// 新增地区属性
@property (nonatomic, copy) NSString *selectedCountryCode; // 选中的地区代码（如"cn"代表中国）
@end




NS_ASSUME_NONNULL_END
