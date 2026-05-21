//
//  UserFeedbackModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import <Foundation/Foundation.h>
#import <IGListDiffable.h>
#import <YYModel/YYModel.h>
#import <Masonry/Masonry.h>

NS_ASSUME_NONNULL_BEGIN
// 反馈处理进度状态
typedef NS_ENUM(NSInteger, FeedbackProgressStatus) {
    FeedbackProgressStatusPending       = 0,    ///< 未处理
    FeedbackProgressStatusProcessing    = 1,    ///< 处理中
    FeedbackProgressStatusResolved      = 2,    ///< 已解决
    FeedbackProgressStatusClosed        = 3     ///< 已关闭
};

// 反馈类型
typedef NS_ENUM(NSInteger, FeedbackType) {
    FeedbackTypeFeatureSuggestion   = 1,    ///< 功能建议
    FeedbackTypeProgramBug          = 2,    ///< 程序Bug
    FeedbackTypeInterfaceOptimization = 3,  ///< 界面优化
    FeedbackTypeContentError        = 4,    ///< 内容错误
    FeedbackTypeAccountIssue        = 5,    ///< 账号问题
    FeedbackTypeOther               = 6     ///< 其他
};


@interface UserFeedbackModel : NSObject <IGListDiffable>

// 数据库字段对应属性
@property (nonatomic, assign) NSInteger feedback_id;      // 主键ID
@property (nonatomic, copy) NSString *user_id;            // 用户ID
@property (nonatomic, copy) NSString *udid;               // 设备唯一标识符
@property (nonatomic, copy) NSString *feedback_content;   // 反馈内容
@property (nonatomic, strong) NSDate *feedback_time;      // 反馈提交时间
@property (nonatomic, assign) NSInteger progress_status;  // 处理进度状态
@property (nonatomic, strong) NSDate *handle_time;        // 处理完成时间
@property (nonatomic, assign) NSInteger feedback_type;    // 反馈类型
@property (nonatomic, copy) NSString *contact_way;        // 用户预留联系方式
@property (nonatomic, copy) NSString *admin_beizhu;       // 管理员回复 备注

// 状态和类型的文本描述（计算属性）
@property (nonatomic, readonly) NSString *progress_status_text;
@property (nonatomic, readonly) NSString *feedback_type_text;


@end

NS_ASSUME_NONNULL_END
