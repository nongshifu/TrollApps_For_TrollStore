//
//  MediaItem.m
//  TrollApps
//
//  媒体文件数据模型 - 用于发布/编辑页面
//

#import "MediaItemModel.h"
#import <AVFoundation/AVFoundation.h>

@implementation MediaItemModel

+ (instancetype)itemWithLocalImage:(UIImage *)image {
    MediaItemModel *item = [[MediaItemModel alloc] init];
    item.identifier = [[NSUUID UUID] UUIDString];
    item.mediaType = MediaItemTypeImage;
    item.source = MediaSourceNew;
    item.localImage = image;
    return item;
}

+ (instancetype)itemWithLocalVideoURL:(NSURL *)videoURL thumbnail:(UIImage *)thumbnail duration:(CGFloat)duration {
    MediaItemModel *item = [[MediaItemModel alloc] init];
    item.identifier = [[NSUUID UUID] UUIDString];
    item.mediaType = MediaItemTypeVideo;
    item.source = MediaSourceNew;
    item.localVideoURL = videoURL;
    item.thumbnailImage = thumbnail;
    item.videoDuration = duration;
    return item;
}

+ (instancetype)itemWithLocalData:(NSData *)data type:(MediaItemType)type {
    MediaItemModel *item = [[MediaItemModel alloc] init];
    item.identifier = [[NSUUID UUID] UUIDString];
    item.mediaType = type;
    item.source = MediaSourceNew;
    item.localData = data;
    return item;
}

+ (instancetype)itemWithFileName:(NSString *)fileName fileURL:(NSString *)fileURL isVideo:(BOOL)isVideo {
    return [self itemWithFileName:fileName fileURL:fileURL thumbnailURL:nil isVideo:isVideo];
}

+ (instancetype)itemWithFileName:(NSString *)fileName fileURL:(NSString *)fileURL thumbnailURL:(NSString *)thumbnailURL isVideo:(BOOL)isVideo {
    MediaItemModel *item = [[MediaItemModel alloc] init];
    item.identifier = [[NSUUID UUID] UUIDString];
    item.mediaType = isVideo ? MediaItemTypeVideo : MediaItemTypeImage;
    item.source = MediaSourceExisting;
    item.fileName = fileName;
    item.fileURL = fileURL;
    item.thumbnailURL = thumbnailURL;
    item.pendingDelete = NO;
    return item;
}

- (BOOL)isVideo {
    return self.mediaType == MediaItemTypeVideo;
}

- (NSString *)displayURL {
    if (self.source == MediaSourceNew) {
        if (self.mediaType == MediaItemTypeImage && self.localImage) {
            return nil; // 本地图片需要用localImage显示
        } else if (self.mediaType == MediaItemTypeVideo && self.localVideoURL) {
            return self.localVideoURL.absoluteString;
        }
        return nil;
    }
    return self.fileURL;
}

- (NSString *)displayThumbnailURL {
    if (self.source == MediaSourceNew) {
        if (self.mediaType == MediaItemTypeVideo) {
            // 本地视频返回缩略图
            if (self.thumbnailImage) {
                return nil; // 使用thumbnailImage显示
            }
        }
        return nil;
    }
    // 服务器视频返回缩略图URL
    return self.thumbnailURL;
}

@end
