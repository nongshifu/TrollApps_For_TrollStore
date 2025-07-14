//
//  ITunesAppModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ITunesAppModel : NSObject

@property (nonatomic, copy) NSString *trackName;        // 应用名称
@property (nonatomic, copy) NSString *bundleId;       // 包名
@property (nonatomic, copy) NSString *trackId;        // 商店ID
@property (nonatomic, copy) NSString *artistName;     // 开发者名称
@property (nonatomic, copy) NSString *artworkUrl512;        // 图标地址（高清）
@property (nonatomic, copy) NSString *appDescription;        // 应用简介
@property (nonatomic, copy) NSString *releaseDate;    // 发布日期
@property (nonatomic, assign) CGFloat price;          // 价格
@property (nonatomic, copy) NSString *currency;       // 货币单位
@property (nonatomic, copy) NSString *trackViewUrl;   // App Store链接
@property (nonatomic, assign) double averageUserRating;//评分
@property (nonatomic, copy) NSString *primaryGenreName;//主要的类别

@property (nonatomic, strong) NSArray<NSString *> *screenshotUrls; // 截图URL数组
@property (nonatomic, strong) NSArray<NSString *> *ipadScreenshotUrls; // iPad截图URL数组


+ (instancetype)modelWithDictionary:(NSDictionary *)dict ;
@end

NS_ASSUME_NONNULL_END
