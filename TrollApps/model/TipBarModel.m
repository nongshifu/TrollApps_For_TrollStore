//
//  TipBarModel.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/2/24.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TipBarModel.h"

@implementation TipBarModel
// 实现diffIdentifier方法，返回能唯一标识该评论模型的对象，这里使用replyID作为唯一标识
- (id<NSObject>)diffIdentifier {
    return self.tipText;
}

// 实现isEqualToDiffableObject:方法，用于对比两个CommentModel对象是否相等（基于replyID来判断）
- (BOOL)isEqualToDiffableObject:(id<NSObject>)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[TipBarModel class]]) {
        return NO;
    }
    TipBarModel *otherModel = (TipBarModel *)object;
    return self.tipText == otherModel.tipText;
}

- (instancetype)initWithIconURL:(NSString *)iconURL
                       tipText:(NSString *)tipText
              leftButtonText:(NSString *)leftButtonText
             rightButtonText:(NSString *)rightButtonText {
    self = [super init];
    if (self) {
        self.iconURL = iconURL;
        self.tipText = tipText;
        self.leftButtonText = leftButtonText;
        self.rightButtonText = rightButtonText;
        
    }
    return self;
}

@end
