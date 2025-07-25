// UploadFileItem.h
#import <Foundation/Foundation.h>
#import "YYModel.h"

typedef NS_ENUM(NSInteger, UploadFileStatus) {
    UploadFileStatusReady = 0,     // 准备上传
    UploadFileStatusUploading = 1, // 上传中
    UploadFileStatusCompleted = 2, // 上传完成
    UploadFileStatusFailed = 3     // 上传失败
};

@interface UploadFileItem : NSObject <YYModel>

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileURL;
@property (nonatomic, assign) UploadFileStatus status;
@property (nonatomic, assign) float progress;
//@property (nonatomic, strong) NSError *error;

@end
