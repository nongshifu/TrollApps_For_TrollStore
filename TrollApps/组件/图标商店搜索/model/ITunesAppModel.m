//
//  ITunesAppModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "ITunesAppModel.h"

@implementation ITunesAppModel

+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    if (!dict) return nil;
    
    ITunesAppModel *model = [[ITunesAppModel alloc] init];
    model.trackName = dict[@"trackName"];
    model.bundleId = dict[@"bundleId"];
    model.trackId = [dict[@"trackId"] stringValue];
    model.artistName = dict[@"artistName"];
    model.appDescription = dict[@"description"];
    model.releaseDate = dict[@"releaseDate"];
    model.price = [dict[@"price"] floatValue];
    model.currency = dict[@"currency"];
    model.trackViewUrl = dict[@"trackViewUrl"];
    model.primaryGenreName = dict[@"primaryGenreName"];
    model.averageUserRating = [dict[@"averageUserRating"] doubleValue];
    // 处理图标URL（替换为1024x1024高清图）
    model.artworkUrl512 = dict[@"artworkUrl512"];;
    // 解析截图URL
    model.screenshotUrls = dict[@"screenshotUrls"]; // 普通截图
    model.ipadScreenshotUrls = dict[@"ipadScreenshotUrls"]; // iPad专用截图
    
    return model;
}

@end
