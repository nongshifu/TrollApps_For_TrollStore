//
//  getTimeID.m
//  SoulChat
//
//  Created by 十三哥 on 2024/1/3.
//

#import "TimeTool.h"

@implementation TimeTool
#pragma mark - 时区设置
+ (NSTimeZone *)beijingTimeZone {
    return [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
}

#pragma mark - 获取当前北京时间
+ (NSDate *)currentBeijingDate {
    NSDate *date = [NSDate date];
    NSTimeInterval timeZoneOffset = [[self beijingTimeZone] secondsFromGMTForDate:date];
    return [date dateByAddingTimeInterval:timeZoneOffset];
}

#pragma mark - 获取当天0点的毫秒时间戳
+ (NSInteger)getTimeIdForToday:(NSDate *)time {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[self beijingTimeZone]];
    
    NSDate *startOfDay = [calendar startOfDayForDate:time];
    NSTimeInterval timeInterval = [time timeIntervalSinceDate:startOfDay];
    return (NSInteger)(timeInterval * 1000);
}

#pragma mark - 获取从2001年1月1日开始的微秒时间戳
+ (NSInteger)getTimeIdFor2001:(NSDate *)time {
    NSTimeInterval timeInterval = [time timeIntervalSinceReferenceDate];
    return (NSInteger)(timeInterval * 1000000);
}

#pragma mark - 获取从2024年1月1日开始的微秒时间戳
+ (NSInteger)getTimeIdFor2024 {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[self beijingTimeZone]];
    
    NSDate *startDate = [formatter dateFromString:@"2024-01-01 00:00:00"];
    NSTimeInterval timeInterval = [[self currentBeijingDate] timeIntervalSinceDate:startDate];
    return (NSInteger)(timeInterval * 1000000);
}

#pragma mark - 获取基于日期的唯一ID（格式：年月日时分秒）
+ (NSInteger)getTimeIdFromDate:(NSDate *)time {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[self beijingTimeZone]];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:time];
    
    return (components.year * 10000000000) + (components.month * 100000000) + (components.day * 1000000) + (components.hour * 10000) + (components.minute * 100) + components.second;
}

#pragma mark - 格式化日期
+ (NSString *)formatDate:(NSDate *)date withFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    [formatter setTimeZone:[self beijingTimeZone]];
    return [formatter stringFromDate:date];
}

#pragma mark - 获取时间差描述（多少前/后）
+ (NSString *)getTimeDiy:(NSDate *)time {
    NSString *timeAgo = [self getTimeAgoStringFromPostDate:time];
    
    return timeAgo;
}
#pragma mark - 获取时间差描述（多少前/后）
+ (NSString *)getTimeDiyWithString:(NSString *)time {
    NSDate *date = [TimeTool getdateFromString:time];
    return [self getTimeAgoStringFromPostDate:date];
}
#pragma mark - 获取时间差描述（带具体时间）
+ (NSString *)getTimeDiyWithDetail:(NSDate *)time {
    NSString *timeAgo = [self getTimeAgoStringFromPostDate:time];
    
    NSString *detailTime = [self formatDate:time withFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [NSString stringWithFormat:@"%@ (%@)", timeAgo, detailTime];
}
#pragma mark - 获取时间差描述（带具体时间）
+ (NSString *)getTimeDiyWithDetailString:(NSString *)time {
    NSDate *date = [TimeTool getdateFromString:time];
    NSString *timeAgo = [self getTimeAgoStringFromPostDate:date];
    
    NSString *detailTime = [self formatDate:date withFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [NSString stringWithFormat:@"%@ (%@)", timeAgo, detailTime];
}
#pragma mark - 计算年龄
+ (NSInteger)calculateAgeFromBirthDate:(NSDate *)birthDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[self beijingTimeZone]];
    
    NSDateComponents *birthComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:birthDate];
    NSDateComponents *currentComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[self currentBeijingDate]];
    
    NSInteger age = currentComponents.year - birthComponents.year;
    
    if ((currentComponents.month < birthComponents.month) ||
        (currentComponents.month == birthComponents.month && currentComponents.day < birthComponents.day)) {
        age--;
    }
    
    return age;
}

#pragma mark - 计算两个日期之间的天数
+ (NSInteger)getDaysBetweenDate:(NSDate *)date1 andDate:(NSDate *)date2 {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[self beijingTimeZone]];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date1 toDate:date2 options:0];
    return [components day];
}

#pragma mark - 获取当前时间戳（秒）
+ (NSTimeInterval)getTimeStamp {
    return [[self currentBeijingDate] timeIntervalSince1970];
}
/// 返回当前时间戳（以秒为单位）
+ (NSString*)getTimeStampWith:(NSDate*)date{
    // 获取当前时间戳（秒）
    NSTimeInterval timestamp = [date timeIntervalSince1970];
    NSInteger seconds = (NSInteger)timestamp;
    NSLog(@"当前时间戳（秒）: %ld", (long)seconds);
    return [NSString stringWithFormat:@"%ld",seconds];
}
#pragma mark - 获取唯一ID（时间戳 + 随机数）
+ (NSString *)getUniqueStringID {
    NSTimeInterval timeStampInMilliseconds = [[self currentBeijingDate] timeIntervalSince1970] * 1000;
    NSString *timeStampString = [NSString stringWithFormat:@"%llu", (unsigned long long)timeStampInMilliseconds];
    NSString *randomNumberString = [NSString stringWithFormat:@"%04u", arc4random_uniform(10000)];
    return [NSString stringWithFormat:@"%@%@", timeStampString, randomNumberString];
}

#pragma mark - 辅助方法：根据时间差返回描述
+ (NSString *)timeStringFromInterval:(NSTimeInterval)timeInterval {
    if (timeInterval < 60) {
        return [NSString stringWithFormat:@"%ld秒", (long)timeInterval];
    } else if (timeInterval < 3600) {
        return [NSString stringWithFormat:@"%ld分钟", (long)(timeInterval / 60)];
    } else if (timeInterval < 86400) {
        return [NSString stringWithFormat:@"%ld小时", (long)(timeInterval / 3600)];
    } else if (timeInterval < (86400 * 31)) {
        return [NSString stringWithFormat:@"%ld天", (long)(timeInterval / 86400)];
    } else if (timeInterval < (86400 * 365)) {
        return [NSString stringWithFormat:@"%ld个月", (long)(timeInterval / (86400 * 30))];
    } else {
        return [NSString stringWithFormat:@"%ld年", (long)(timeInterval / (86400 * 365))];
    }
}

+ (NSString *)getTimeformatDateUnsigned:(NSDate *)time {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *formattedDate = [formatter stringFromDate:time];
    return formattedDate;
}

+ (NSString *)getTimeformatDate:(NSDate *)time {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *formattedDate = [formatter stringFromDate:time];
    return formattedDate;
}
+ (NSString *)getTimeformatDateForDay:(NSDate *)time {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return [dateFormatter stringFromDate:time]; // 格式化当前时间为字符串
}

+ (NSString *)getTimestr:(NSDate *)time {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:time]; // 格式化当前时间为字符串
}

+ (NSDate *)getdateFromString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}
+ (NSString *)getTimeAgoStringFromPostDate:(NSDate *)postDate {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:postDate];
    NSInteger seconds = round(interval);
    NSInteger minutes = round(interval / 60);
    NSInteger hours = round(interval / 3600);
    NSInteger days = round(interval / (3600 * 24));
    NSInteger months = round(interval / (3600 * 24 * 30));
    NSInteger years = round(interval / (3600 * 24 * 30 * 12));
    
    NSString *timeAgoString = @"";
    if (seconds <= 0) {
        timeAgoString = @"刚刚";
    }
    else if (seconds < 60) {
        timeAgoString = [NSString stringWithFormat:@"%ld秒前", seconds];
    } else if (minutes < 60) {
        timeAgoString = [NSString stringWithFormat:@"%ld分钟前", minutes];
    } else if (hours < 24) {
        timeAgoString = [NSString stringWithFormat:@"%ld小时前", hours];
    } else if (days < 30) {
        timeAgoString = [NSString stringWithFormat:@"%ld天前", days];
    } else if (months < 12) {
        timeAgoString = [NSString stringWithFormat:@"%ld个月前", months];
    } else {
        timeAgoString = [NSString stringWithFormat:@"%ld年前", years];
    }
    
    return timeAgoString;
}

+ (NSInteger)getAge:(NSDate *)birthDate {
    if (!birthDate) {
        NSLog(@"Invalid birth date");
        return -1; // 返回 -1 表示日期无效
    }
    
    // 获取当前日期
    NSDate *currentDate = [NSDate date];
    
    // 创建日历对象
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // 计算出生日期的年、月、日
    NSDateComponents *birthComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:birthDate];
    
    // 计算当前日期的年、月、日
    NSDateComponents *currentComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:currentDate];
    
    NSInteger age = currentComponents.year - birthComponents.year;
    
    // 如果当前日期在出生日期之前，年龄减一
    if ((currentComponents.month < birthComponents.month) ||
        (currentComponents.month == birthComponents.month && currentComponents.day < birthComponents.day)) {
        age--;
    }
    
    return age;
}

// 返回用于做唯一ID的数值，结合时间戳和4位随机数
+ (NSUInteger)getUniqueID {
    // 获取当前时间戳（精确到毫秒）
    NSTimeInterval timeStampInMilliseconds = [[NSDate date] timeIntervalSince1970] * 1000;
    // 将时间戳转换为整数部分（向下取整）
    NSUInteger timeStampInteger = (NSUInteger)timeStampInMilliseconds;
    // 生成4位随机数字
    NSUInteger randomNumber = arc4random_uniform(10000);
    // 通过移位和加法运算将时间戳整数和随机数组合成一个数值
    NSUInteger uniqueID = (timeStampInteger << 16) + randomNumber;
    return uniqueID;
}
//传入long long 时间戳
+ (NSString *)getTimeFromTimestamp:(long long)timestamp {
    // 创建 NSDate 对象，将时间戳转换为秒
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
    
    // 创建日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // 设置日期格式，这里使用的是常见的格式，你可以根据需求修改
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    // 将 NSDate 对象转换为字符串
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}
//传入long long 时间戳
+ (NSDate *)getTimeDateFromTimestamp:(long long)timestamp {
    // 创建 NSDate 对象，将时间戳转换为秒
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
    
    
    return date;
}

+ (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy/MM/dd";
    return [formatter stringFromDate:date];
}

+ (NSString *)dateStringToYearMonthDay:(NSString *)dateString {
    if(!dateString || dateString.length<8 || ![dateString containsString:@":"] || ![dateString containsString:@"-"])return nil;
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    NSDate *date = [inputFormatter dateFromString:dateString];
    if (!date) {
        NSLog(@"日期字符串格式不正确: %@", dateString);
        return nil;
    }
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateFormat = @"yyyy/MM/dd";
    
    return [outputFormatter stringFromDate:date];
}
@end
