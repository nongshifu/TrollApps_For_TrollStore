//
//  ShowOneAppViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "TemplateListController.h"
#import "AppInfoModel.h"
#import "TipBarModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowOneAppViewController : TemplateListController
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, strong) AppInfoModel *appInfo;

@end

NS_ASSUME_NONNULL_END
