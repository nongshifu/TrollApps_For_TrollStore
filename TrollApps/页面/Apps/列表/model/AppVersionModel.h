//
//  AppVersionModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppVersionModel : NSObject
@property (nonatomic, assign) NSInteger version_id;
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, assign) NSInteger version_code;
@property (nonatomic, copy) NSString *version_name;
@property (nonatomic, copy) NSString *release_notes;
@property (nonatomic, assign) NSInteger version_type;
@property (nonatomic, strong) NSDate *add_date;
@property (nonatomic, strong) NSDate *update_date;
@end

NS_ASSUME_NONNULL_END
