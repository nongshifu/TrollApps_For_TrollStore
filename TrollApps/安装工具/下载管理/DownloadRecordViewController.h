//
//  DownloadRecordViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/9.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "DownloadRecordModel.h"
#import "DownloadRecordCell.h"
#import "config.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadRecordViewController : TemplateListController
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, assign) BOOL sortType;
@end

NS_ASSUME_NONNULL_END
