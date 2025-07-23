//
//  NetworkClient.h
//  TrollApps
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkRequestMethod) {
    NetworkRequestMethodGET,
    NetworkRequestMethodPOST
};

typedef void(^WebProgressBlock)(NSProgress *progress);
typedef void(^WebSuccessBlock)(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult);
typedef void(^WebFailureBlock)(NSError *error);

@class NetworkClient;

@protocol NetworkClientDelegate <NSObject>
@optional
- (void)networkClient:(NetworkClient *)client uploadTask:(NSURLSessionUploadTask *)task didUpdateProgress:(float)progress;
@end

@interface NetworkClient : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionUploadTask *, WebProgressBlock> *progressBlockMap;
@property (nonatomic, weak) id<NetworkClientDelegate> delegate;

+ (instancetype)sharedClient;

/**
 * 发送网络请求
 * @param method 请求方法（GET/POST）
 * @param urlString 请求URL
 * @param parameters 请求参数
 * @param udid 设备唯一标识
 * @param progressBlock 进度回调
 * @param successBlock 成功回调（包含JSON、字符串和原始数据三种格式的结果）
 * @param failureBlock 失败回调
 */
- (NSURLSessionDataTask *)sendRequestWithMethod:(NetworkRequestMethod)method
                    urlString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                         udid:(NSString *)udid
                     progress:(WebProgressBlock)progressBlock
                      success:(WebSuccessBlock)successBlock
                      failure:(WebFailureBlock)failureBlock;

/**
 * 上传文件
 * @param urlString 请求URL
 * @param fileData 文件数据
 * @param fileName 文件名
 * @param parameters 请求参数
 * @param udid 设备唯一标识
 * @param progressBlock 进度回调
 * @param successBlock 成功回调
 * @param failureBlock 失败回调
 */
- (NSURLSessionUploadTask *)uploadFileWithURLString:(NSString *)urlString
                       fileData:(NSData *)fileData
                       fileName:(NSString *)fileName
                     parameters:(NSDictionary *)parameters
                           udid:(NSString *)udid
                       progress:(WebProgressBlock)progressBlock
                        success:(WebSuccessBlock)successBlock
                        failure:(WebFailureBlock)failureBlock;

/**
 将字符串URL转换为编码后的NSURL（保留原始空格和/）
 
 @param urlString 原始URL字符串（可能包含未编码的中文或特殊字符）
 @return 编码后的NSURL（nil表示转换失败）
 */
+ (NSURL *)encodedURLFromString:(NSString *)urlString;

@end
