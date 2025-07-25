//
//  InjectionRecord.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "InjectionRecord.h"

@implementation InjectionRecord

// NSCoding协议实现（用于本地存储）
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.appName forKey:@"appName"];
    [coder encodeObject:self.appBundleID forKey:@"appBundleID"];
    [coder encodeObject:self.dylibPath forKey:@"dylibPath"];
    [coder encodeObject:self.injectionTime forKey:@"injectionTime"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.appName = [coder decodeObjectForKey:@"appName"];
        self.appBundleID = [coder decodeObjectForKey:@"appBundleID"];
        self.dylibPath = [coder decodeObjectForKey:@"dylibPath"];
        self.injectionTime = [coder decodeObjectForKey:@"injectionTime"];
    }
    return self;
}
@end
