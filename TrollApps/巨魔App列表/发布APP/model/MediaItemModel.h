//
//  MediaItem.h
//  TrollApps
//
//  媒体文件数据模型 - 用于发布/编辑页面
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MediaItemType) {
    MediaItemTypeImage = 0,
    MediaItemTypeVideo = 1,
    MediaItemTypeMainFile = 2,
    MediaItemTypeIcon = 3
};

typedef NS_ENUM(NSInteger, MediaSource) {
    MediaSourceNew = 0,      // 新上传的
    MediaSourceExisting = 1  // 现有服务器上的
};

@interface MediaItemModel : NSObject

@property (nonatomic, strong) NSString *identifier;  // 唯一标识符(UUID)
@property (nonatomic, assign) MediaItemType mediaType;  // 文件类型
@property (nonatomic, assign) MediaSource source;    // 来源

// 文件信息
@property (nonatomic, strong, nullable) NSString *fileName;      // 服务器文件名(现有文件)
@property (nonatomic, strong, nullable) NSString *fileURL;       // 文件URL(现有文件)
@property (nonatomic, strong, nullable) NSString *thumbnailURL;   // 视频缩略图URL
@property (nonatomic, strong, nullable) NSString *relativePath;    // 相对路径
@property (nonatomic, assign) NSInteger fileSize;                 // 文件大小

// 本地文件信息(新上传)
@property (nonatomic, strong, nullable) NSData *localData;       // 本地文件数据
@property (nonatomic, strong, nullable) UIImage *localImage;      // 本地图片预览
@property (nonatomic, strong, nullable) NSURL *localVideoURL;     // 本地视频URL
@property (nonatomic, strong, nullable) UIImage *thumbnailImage;  // 本地视频缩略图
@property (nonatomic, assign) CGFloat videoDuration;              // 视频时长

// 上传状态
@property (nonatomic, assign) BOOL isUploading;    // 是否正在上传
@property (nonatomic, assign) CGFloat uploadProgress; // 上传进度
@property (nonatomic, assign) BOOL uploadSuccess;  // 是否上传成功
@property (nonatomic, strong, nullable) NSString *uploadError; // 上传错误信息

// 待删除标记(仅现有文件)
@property (nonatomic, assign) BOOL pendingDelete;

// 创建新媒体项(本地)
+ (instancetype)itemWithLocalImage:(UIImage *)image;
+ (instancetype)itemWithLocalVideoURL:(NSURL *)videoURL thumbnail:(UIImage *)thumbnail duration:(CGFloat)duration;
+ (instancetype)itemWithLocalData:(NSData *)data type:(MediaItemType)type;

// 创建现有媒体项(服务器)
+ (instancetype)itemWithFileName:(NSString *)fileName fileURL:(NSString *)fileURL isVideo:(BOOL)isVideo;
+ (instancetype)itemWithFileName:(NSString *)fileName fileURL:(NSString *)fileURL thumbnailURL:(nullable NSString *)thumbnailURL isVideo:(BOOL)isVideo;

// 判断是否是视频
- (BOOL)isVideo;

// 获取显示用URL
- (nullable NSString *)displayURL;

// 获取缩略图URL(用于视频)
- (nullable NSString *)displayThumbnailURL;

@end

NS_ASSUME_NONNULL_END
