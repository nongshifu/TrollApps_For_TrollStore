//
//  TipBarModel.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/2/24.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

NS_ASSUME_NONNULL_BEGIN

@interface TipBarModel : NSObject<IGListDiffable>


@property (nonatomic, copy) NSString *iconURL;  // 图标 URL
@property (nonatomic, copy) NSString *tipText;  // 提示文字
@property (nonatomic, copy) NSString *leftButtonText;  // 左边按钮文字
@property (nonatomic, copy) NSString *rightButtonText;  // 右边按钮文字

- (instancetype)initWithIconURL:(NSString *)iconURL
                       tipText:(NSString *)tipText
              leftButtonText:(NSString *)leftButtonText
             rightButtonText:(NSString *)rightButtonText;

@end


NS_ASSUME_NONNULL_END
