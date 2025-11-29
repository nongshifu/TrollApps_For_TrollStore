//
//  NetworkClient.m
//  TrollApps
//

#import "NetworkClient.h"
#import "TokenGenerator.h"

//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface NetworkClient ()

@property (nonatomic, strong) TokenGenerator *tokenGenerator;

@end

@implementation NetworkClient

+ (instancetype)sharedClient {
    static NetworkClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tokenGenerator = [TokenGenerator sharedGenerator];
        _progressBlockMap = [NSMutableDictionary dictionary];
        
    }
    return self;
}
                

- (NSURLSessionDataTask *)sendRequestWithMethod:(NetworkRequestMethod)method
                                      urlString:(NSString *)urlString
                                     parameters:(NSDictionary *)parameters
                                           udid:(NSString *)udid
                                       progress:(WebProgressBlock)progressBlock
                                        success:(WebSuccessBlock)successBlock
                                        failure:(WebFailureBlock)failureBlock {
    
    // 生成Token
    NSString *token = [self.tokenGenerator generateTokenWithUDID:udid];
    if (!token) {
        if (failureBlock) {
            NSError *error = [NSError errorWithDomain:@"NetworkClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Token生成失败"}];
            NSLog(@"请求token失败：%@", error);
            failureBlock(error);
        }
        return nil;
    }
    
    // 构建请求参数
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    requestParams[@"udid"] = udid;
    requestParams[@"token"] = token;
    requestParams[@"data"] = parameters ?: @{};
    
    NSString *aciton = parameters[@"action"];
    if(aciton){
        requestParams[@"action"] = aciton;
    }
    NSLog(@"构建请求requestParams：%@", requestParams);
    NSLog(@"构建请求udid：%@", udid);
    NSLog(@"构建请求token：%@", token);
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = (method == NetworkRequestMethodGET) ? @"GET" : @"POST";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:udid forHTTPHeaderField:@"X-UDID"];
    [request addValue:token forHTTPHeaderField:@"X-Token"];
    NSLog(@"构建请求：%@", request);
    
    // 处理GET请求参数
    if (method == NetworkRequestMethodGET) {
        NSString *queryString = [self queryStringFromParameters:requestParams];
        if (queryString.length > 0) {
            if ([urlString rangeOfString:@"?"].location == NSNotFound) {
                urlString = [urlString stringByAppendingFormat:@"?%@", queryString];
            } else {
                urlString = [urlString stringByAppendingFormat:@"&%@", queryString];
            }
            request.URL = [NSURL URLWithString:urlString];
        }
    }
    // 处理POST请求参数
    else {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestParams options:0 error:&error];
        if (error) {
            if (failureBlock) {
                failureBlock(error);
            }
            return nil;
        }
        request.HTTPBody = jsonData;
    }
    
    // 创建数据任务
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        // 解析响应
        NSError *parseError;
        NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (successBlock) {
            successBlock(jsonResult, stringResult, data);
        }
    }];
    
    // 设置进度回调
    if (progressBlock) {
        [task resume];
        progressBlock(task.progress);
    } else {
        [task resume];
    }
    
    return task;
}

                  
- (NSURLSessionUploadTask *)uploadFileWithURLString:(NSString *)urlString
                                            fileData:(NSData *)fileData
                                            fileName:(NSString *)fileName
                                          parameters:(NSDictionary *)parameters
                                                udid:(NSString *)udid
                                            progress:(WebProgressBlock)progressBlock
                                             success:(WebSuccessBlock)successBlock
                                             failure:(WebFailureBlock)failureBlock {
    NSLog(@"请求的URL:%@",urlString);
    NSLog(@"请求的fileName:%@",fileName);
    NSLog(@"请求的fileData:%@",fileData);
    // 生成Token
    NSString *token = [self.tokenGenerator generateTokenWithUDID:udid];
    if (!token) {
        if (failureBlock) {
            NSError *error = [NSError errorWithDomain:@"NetworkClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Token生成失败"}];
            failureBlock(error);
        }
        return nil;
    }
    
    // 构建请求参数：将parameters序列化为标准JSON字符串（关键修复）
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    requestParams[@"udid"] = udid;
    requestParams[@"token"] = token;
    if(parameters[@"action"]){
        requestParams[@"action"] = parameters[@"action"];
    }
    if(parameters[@"type"]){
        requestParams[@"type"] = parameters[@"type"];
    }
    
    // 将parameters（含action、app_id等）转换为标准JSON字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters ?: @{} options:0 error:NULL];
    NSString *dataJsonString = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";
    requestParams[@"data"] = dataJsonString; // 传递JSON字符串而非字典
    
    NSLog(@"最终封装后的requestParams：%@", requestParams);
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    
    // 设置请求头（multipart/form-data）
    NSString *boundary = [self generateBoundaryString];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request addValue:udid forHTTPHeaderField:@"X-UDID"];
    [request addValue:token forHTTPHeaderField:@"X-Token"];
    
    // 构建请求体（multipart/form-data格式）
    NSMutableData *body = [NSMutableData data];
    
    // 添加参数（udid、token、data）
    [requestParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[value dataUsingEncoding:NSUTF8StringEncoding]]; // 直接使用字符串编码，避免格式错误
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // 添加文件数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.HTTPBody = body;
    
    // 创建上传任务
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil]; // 不要使用mainQueue，避免阻塞主线程
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        // 解析响应
        NSError *parseError;
        NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (successBlock) {
            successBlock(jsonResult, stringResult, data);
        }
    }];
    
    // 进度回调处理（使用NSURLSessionTaskDelegate监控进度）
    [uploadTask resume];
    // 保存进度回调
    if (progressBlock) {
        self.progressBlockMap[uploadTask] = [progressBlock copy];
    }
    
    return uploadTask;
}


#pragma mark - Private Methods

- (NSString *)queryStringFromParameters:(NSDictionary *)parameters {
    NSMutableArray *components = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *encodedKey = [self urlEncodeString:[key description]];
        NSString *encodedValue = [self urlEncodeString:[obj description]];
        [components addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }];
    return [components componentsJoinedByString:@"&"];
}

- (NSString *)urlEncodeString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (NSString *)generateBoundaryString {
    return [NSString stringWithFormat:@"---------------------------%08X%08X", arc4random(), arc4random()];
}

// 实现NSURLSessionTaskDelegate协议方法
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    // 计算进度
    float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
    
    // 通过代理回调进度
    if ([self.delegate respondsToSelector:@selector(networkClient:uploadTask:didUpdateProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate networkClient:self uploadTask:(NSURLSessionUploadTask *)task didUpdateProgress:progress];
        });
    }
    
    // 通过block回调进度
    WebProgressBlock progressBlock = self.progressBlockMap[(NSURLSessionUploadTask *)task];
    if (progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock(task.progress);
        });
    }
}

// 任务完成后移除映射
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.progressBlockMap removeObjectForKey:(NSURLSessionUploadTask *)task];
}



+ (NSURL *)encodedURLFromString:(NSString *)urlString {
    if (!urlString || urlString.length == 0) {
        NSLog(@"URL字符串为空");
        return nil;
    }
    
    // 1. 拆分URL为"协议://"和"路径部分"（避免对协议部分二次编码）
    NSRange schemeRange = [urlString rangeOfString:@"://"];
    NSString *scheme = @"";
    NSString *pathPart = urlString;
    
    if (schemeRange.location != NSNotFound) {
        scheme = [urlString substringToIndex:schemeRange.location + schemeRange.length];
        pathPart = [urlString substringFromIndex:schemeRange.location + schemeRange.length];
    }
    
    // 2. 对路径部分进行编码（仅编码非URL安全字符，保留/和空格）
    NSString *encodedPathPart = [self encodeURLPathPart:pathPart];
    if (!encodedPathPart) {
        return nil;
    }
    
    // 3. 拼接编码后的完整URL字符串
    NSString *encodedURLString = [scheme stringByAppendingString:encodedPathPart];
    
    // 4. 转换为NSURL（自动处理URL格式校验）
    NSURL *encodedURL = [NSURL URLWithString:encodedURLString];
    if (!encodedURL) {
        NSLog(@"URL格式无效：%@", encodedURLString);
    }
    
    return encodedURL;
}

/**
 编码URL路径部分（保留/和空格）
 
 @param pathPart URL中的路径部分（不含协议头）
 @return 编码后的路径部分
 */
+ (NSString *)encodeURLPathPart:(NSString *)pathPart {
    if (!pathPart) return nil;
    
    // URL安全字符集：保留字母、数字、以及;/?:@&=+$,#和/、空格
    // 注意：空格在这里不替换为%20，保持原始空格（根据需求）
    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;= "];
    
    // 对不在安全字符集中的字符进行编码（如中文、特殊符号）
    return [pathPart stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
}


@end
