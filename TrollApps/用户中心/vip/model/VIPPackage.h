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

@property (nonatomic, copy) NSString *packageId;       // 对应JSON的packageId
@property (nonatomic, assign) NSInteger downloadsNumber;// 对应JSON的downloadsNumber
@property (nonatomic, copy) NSString *title;            // 对应JSON的title
@property (nonatomic, copy) NSString *vipDescription;   // 对应JSON的vipDescription
@property (nonatomic, copy) NSString *price;            // 对应JSON的price（带¥符号）
@property (nonatomic, assign) NSInteger level;          // 对应JSON的level
@property (nonatomic, assign) NSInteger vipDay;         // 对应JSON的vipDay
@property (nonatomic, copy) NSString *themeColor;       // 对应JSON的themeColor
@property (nonatomic, assign) BOOL isRecommended;       // 对应JSON的isRecommended
@property (nonatomic, copy) NSString *recommendedTitle; // 对应JSON的recommendedTitle

@end

NS_ASSUME_NONNULL_END
