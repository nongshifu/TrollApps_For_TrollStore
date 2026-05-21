//
//  PlistNode.m
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//
#import "PlistNode.h"

@implementation PlistNode

- (instancetype)init {
    self = [super init];
    if (self) {
        _children = [NSMutableArray array];
        _isExpanded = NO;
    }
    return self;
}

+ (PlistType)typeForValue:(id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        return PlistTypeDictionary;
    } else if ([value isKindOfClass:[NSArray class]]) {
        return PlistTypeArray;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        // 判断是否为Bool类型
        const char* type = [value objCType];
        if (strcmp(type, @encode(BOOL)) == 0 || strcmp(type, "c") == 0 || strcmp(type, "C") == 0) {
            return PlistTypeBool;
        } else {
            return PlistTypeNumber;
        }
    } else if ([value isKindOfClass:[NSString class]]) {
        return PlistTypeString;
    } else if ([value isKindOfClass:[NSDate class]]) {
        return PlistTypeDate;
    }
    return PlistTypeString;
}

// 安全递归解析 Plist（字典、数组都支持）
+ (PlistNode *)buildNodeWithKey:(NSString *)key value:(id)value {
    PlistNode *node = [[PlistNode alloc] init];
    node.key = key;
    node.value = value;
    node.type = [self typeForValue:value];
    
    if (node.type == PlistTypeDictionary) {
        NSDictionary *dict = value;
        for (NSString *k in dict.allKeys) {
            PlistNode *child = [PlistNode buildNodeWithKey:k value:dict[k]];
            [node.children addObject:child];
        }
    }
    else if (node.type == PlistTypeArray) {
        NSArray *arr = value;
        for (NSInteger i = 0; i < arr.count; i++) {
            id item = arr[i];
            PlistNode *child = [PlistNode buildNodeWithKey:[NSString stringWithFormat:@"%ld", i] value:item];
            [node.children addObject:child];
        }
    }
    
    return node;
}

@end
