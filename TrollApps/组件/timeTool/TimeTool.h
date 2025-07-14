//
//  getTimeID.h
//  SoulChat
//
//  Created by 十三哥 on 2024/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeTool : NSObject
///返回当天0点微妙级别
+ (NSInteger)getTimeIdForToday:(NSDate *)time;
///返回2001年微妙级别
+ (NSInteger)getTimeIdFor2001:(NSDate *)time;
///返回2024年微妙级别
+ (NSInteger)getTimeIdFor2024;
///返回年月日+时间去掉符号的整数
+ (NSInteger)getTimeIdFromDate:(NSDate *)time;
///返回年月日时间字符串无符号 20241120221301
+ (NSString *)getTimeformatDateUnsigned:(NSDate *)time;
///返回标准时间格式字符串 2024-11-20 22:13:01
+ (NSString *)getTimeformatDate:(NSDate *)time;
///返回年月日不包括时间 格式字符串 2024-11-20
+ (NSString *)getTimeformatDateForDay:(NSDate *)time;
///传入自定义NSDate返回标准日期格式字符串 2024-11-20  22:13:01
+ (NSString *)getTimestr:(NSDate *)time;
///返回自定义diy的时间 比如昨天前天 星期之类的
+ (NSString *)getTimeDiy:(NSDate *)time;
///返回自定义diy的时间 比如昨天前天 星期之类的
+ (NSString *)getTimeDiyWithString:(NSString *)time;
///返回自定义diy的时间 + 具体时间 比如昨天前天 星期之类的
+ (NSString *)getTimeDiyWithDetail:(NSDate *)time;
///返回自定义diy的时间 + 具体时间 比如昨天前天 星期之类的
+ (NSString *)getTimeDiyWithDetailString:(NSString *)time;
///传入字符串 返回NSDate
+ (NSDate *)getdateFromString:(NSString *)dateString;
///传入时间 返回多少分 ,小时,天,月,年 前
+ (NSString *)getTimeAgoStringFromPostDate:(NSDate *)postDate;
///传入时间 返回年龄
+ (NSInteger)getAge:(NSDate *)birthDate;
///其实时间 结束时间 对比返回天数 顺序错会负数
+ (NSInteger)getDaysBetweenDate:(NSDate *)date1 andDate:(NSDate *)date2;
/// 返回当前时间戳（以秒为单位）
+ (NSTimeInterval)getTimeStamp;
/// 返回用于做唯一ID的字符串，结合时间戳和4位随机数
+ (NSString *)getUniqueStringID;
/// 返回用于做唯一ID的数值，结合时间戳和4位随机数
+ (NSUInteger)getUniqueID;
///传入long long 时间戳
+ (NSString *)getTimeFromTimestamp:(long long)timestamp;
//传入long long 时间戳
+ (NSDate *)getTimeDateFromTimestamp:(long long)timestamp;
//传入时间字符串 返回 年/月/日  注意是/分割 做目录路径
+ (NSString *)dateStringToYearMonthDay:(NSString *)dateString;
//传入时间date 返回 年/月/日  注意是/分割 做目录路径
+ (NSString *)stringFromDate:(NSDate *)date;
@end

NS_ASSUME_NONNULL_END
