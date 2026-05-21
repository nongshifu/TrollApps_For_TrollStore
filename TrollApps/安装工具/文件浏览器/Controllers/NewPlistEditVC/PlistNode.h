//
//  PlistNode.h
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PlistType) {
    PlistTypeString,
    PlistTypeNumber,
    PlistTypeBool,
    PlistTypeDate,
    PlistTypeArray,
    PlistTypeDictionary
};

@interface PlistNode : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) PlistType type;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, strong) NSMutableArray *children;

// 🔥 新增：从 Plist 数据自动创建节点树
+ (PlistNode *)buildNodeWithKey:(NSString *)key value:(id)value;

@end

