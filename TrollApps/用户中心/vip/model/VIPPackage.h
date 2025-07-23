//
//  VIPPackage.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <IGListKit/IGListKit.h>
NS_ASSUME_NONNULL_BEGIN


@interface VIPPackage : NSObject <IGListDiffable>

@property (nonatomic, copy) NSString *packageId;      // 套餐ID
@property (nonatomic, copy) NSString *title;          // 套餐标题
@property (nonatomic, copy) NSString *vipDescription;    // 套餐描述
@property (nonatomic, copy) NSString *price;          // 价格
@property (nonatomic, assign) NSInteger level;                // VIP等级
@property (nonatomic, copy) NSString *themeColor;           // 主题色
@property (nonatomic, assign )BOOL isRecommended;             // 是否推荐
@property (nonatomic, copy) NSString *recommendedTitle; //推荐标题

@end

NS_ASSUME_NONNULL_END
