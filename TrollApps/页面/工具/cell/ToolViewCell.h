//
//  ToolViewCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "TemplateCell.h"
#import "WebToolModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface ToolViewCell : TemplateCell
@property (nonatomic, strong) WebToolModel *toolModel;
@end

NS_ASSUME_NONNULL_END
