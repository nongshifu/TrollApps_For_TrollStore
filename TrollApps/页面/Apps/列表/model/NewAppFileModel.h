//
//  AppFileModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewAppFileModel : NSObject
@property (nonatomic, assign) NSInteger file_id;
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, assign) NSInteger version_code;
@property (nonatomic, copy) NSString *file_name;
@property (nonatomic, copy) NSString *file_size;
@property (nonatomic, copy) NSString *suffix;
@property (nonatomic, copy) NSString *file_url;
@property (nonatomic, strong) NSDate *last_modified;
@property (nonatomic, assign) NSInteger file_type;
@end

NS_ASSUME_NONNULL_END
