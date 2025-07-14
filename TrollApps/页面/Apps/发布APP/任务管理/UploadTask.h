//
//  UploadTask.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import "UploadFileItem.h"
#import "YYModel.h"
NS_ASSUME_NONNULL_BEGIN



typedef NS_ENUM(NSInteger, UploadTaskStatus) {
    UploadTaskStatusReady = 0,     // 准备上传
    UploadTaskStatusUploading = 1, // 上传中
    UploadTaskStatusPaused = 2,    // 已暂停
    UploadTaskStatusCompleted = 3, // 上传完成
    UploadTaskStatusFailed = 4     // 上传失败
};

@interface UploadTask : NSObject <YYModel>

@property (nonatomic, copy) NSString *task_id;
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, copy) NSString *app_name;
@property (nonatomic, assign) UploadTaskStatus status;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, copy) NSString *bundle_id;
@property (nonatomic, copy) NSString *version_name;
@property (nonatomic, copy) NSString *release_notes;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *idfv;

@property (nonatomic, strong) NSMutableArray<UploadFileItem *> *fileItems;

@property (nonatomic, strong) NSDictionary *dictionary;

@end
NS_ASSUME_NONNULL_END
