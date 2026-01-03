//
//  MediaItem.h
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN
// 新增枚举区分媒体类型
typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeLocalImage,    // 本地图片
    MediaTypeRemoteImage,   // 远程图片
    MediaTypeLocalVideo,    // 本地视频
    MediaTypeRemoteVideo,   // 远程视频
    MediaTypeLocalAudio,    // 本地音频
    MediaTypeRemoteAudio,   // 远程音频
    MediaTypeLocalFile,     // 本地文件
    MediaTypeRemoteFile,     // 远程文件
    MediaTypeImage,
    MediaTypeVideo,
    MediaTypeAudio
    
};

@interface MediaItem : NSObject
@property (nonatomic, assign) MediaType type;
@property (strong, nonatomic) PHAsset * _Nullable asset;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *localPath; // 本地路径(用于新增)
@property (nonatomic, strong) NSString *remoteUrl; // 远程URL(用于更新)
@property (nonatomic, assign) NSTimeInterval duration; // 时长(r如视频时长 语音时长 等数据)
@property (nonatomic, assign) BOOL isDeleted; // 是否被删除
@property (nonatomic, assign) NSInteger fileSize; // 文件大小
@property (nonatomic, strong) NSString * fileBase64; // 文件编码 （按需储存）
@property (nonatomic, strong) NSData * fileData; // 文件data （按需储存）
@end

NS_ASSUME_NONNULL_END
