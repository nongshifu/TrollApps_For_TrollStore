//
//  FileNotification.h
//  SandboxFileManager
//
//  通知名称常量定义
//

#import <Foundation/Foundation.h>

#ifndef FileNotification_h
#define FileNotification_h

/// 文件列表发生变化的通知
extern NSString * const kNotificationFileListChanged;

/// 收藏状态发生变化的通知
extern NSString * const kNotificationFavoriteChanged;

/// 当前目录发生变化的通知
extern NSString * const kNotificationDirectoryChanged;

#endif
