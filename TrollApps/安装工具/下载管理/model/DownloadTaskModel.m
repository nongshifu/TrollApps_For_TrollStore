//
//  DownloadTaskModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/22.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DownloadTaskModel.h"

@implementation DownloadTaskModel

+ (instancetype)taskWithURL:(NSURL *)url fileName:(NSString *)fileName {
    DownloadTaskModel *model = [[self alloc] init];
    model.taskId = [NSString stringWithFormat:@"%@_%lld", url.absoluteString, (long long)[[NSDate date] timeIntervalSince1970]];
    model.url = url;
    model.fileName = fileName ?: url.lastPathComponent;
    model.status = DownloadStatusWaiting;
    return model;
}

@end
