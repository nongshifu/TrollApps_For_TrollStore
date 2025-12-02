//
//  YSMPayResponseModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface YSMPayResponseModel : NSObject <IGListDiffable>

@property (nonatomic, assign) NSInteger code;         // 状态码（0=成功，其他=失败）
@property (nonatomic, copy) NSString *msg;            // 提示信息（成功/失败原因）
@property (nonatomic, copy) NSString *ordeid;         // 商户订单号（code=0时返回）
@property (nonatomic, copy) NSString *sign;           // 签名（code=0时返回）
@property (nonatomic, copy) NSString *url;            // 支付URL（code=0时返回，跳转/生成二维码用）

// JSON转模型
+ (instancetype)modelWithJSONDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
