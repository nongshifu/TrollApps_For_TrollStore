//
//  AnnouncementManager.m
//  TrollApps
//
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AnnouncementManager.h"
#import "AnnouncementDetailViewController.h"
#import "AnnouncementListViewController.h"
#import "CustomDialogView.h"
#import "NetworkClient.h"
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用
@interface AnnouncementManager ()

@property (nonatomic, strong) NSMutableDictionary *shownAnnouncements;

@end

@implementation AnnouncementManager

static NSString *const kShownAnnouncementsKey = @"AnnouncementManagerShownAnnouncements";
static NSString *const kLatestAnnouncementKey = @"AnnouncementManagerLatestAnnouncement";

+ (instancetype)sharedManager {
    static AnnouncementManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AnnouncementManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadSavedData];
    }
    return self;
}

- (void)loadSavedData {
    // 加载已显示的公告
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *savedShown = [defaults dictionaryForKey:kShownAnnouncementsKey];
    if (savedShown) {
        self.shownAnnouncements = [savedShown mutableCopy];
    } else {
        self.shownAnnouncements = [NSMutableDictionary dictionary];
    }
    
    // 加载保存的最新公告
    NSData *announcementData = [defaults objectForKey:kLatestAnnouncementKey];
    if (announcementData) {
        self.latestAnnouncement = [NSKeyedUnarchiver unarchiveObjectWithData:announcementData];
    }
}

- (void)saveData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.shownAnnouncements copy] forKey:kShownAnnouncementsKey];
    
    if (self.latestAnnouncement) {
        NSData *announcementData = [NSKeyedArchiver archivedDataWithRootObject:self.latestAnnouncement];
        [defaults setObject:announcementData forKey:kLatestAnnouncementKey];
    }
    
    [defaults synchronize];
}

#pragma mark - Public Methods

- (BOOL)hasShownAnnouncement:(AnnouncementModel *)announcement {
    if (!announcement) return NO;
    return self.shownAnnouncements[announcement.announcement_uuid] != nil;
}

- (AnnouncementDisplayState)shouldDisplayAnnouncement:(AnnouncementModel *)announcement {
    if (!announcement) return AnnouncementDisplayStateNone;
    
    // 检查公告是否激活
    if (!announcement.isActive) return AnnouncementDisplayStateNone;
    
    // 检查是否过期
    if ([announcement isExpired]) return AnnouncementDisplayStateNone;
    
    // 根据弹窗模式判断
    switch (announcement.announcement_popup_mode) {
        case AnnouncementPopupModeNone:
            return AnnouncementDisplayStateNone;
            
        case AnnouncementPopupModeClosable:
        case AnnouncementPopupModeForced:
            return AnnouncementDisplayStateEveryTime;
            
        case AnnouncementPopupModeOnce:
            if ([self hasShownAnnouncement:announcement]) {
                return AnnouncementDisplayStateNone;
            }
            return AnnouncementDisplayStateOnce;
            
        default:
            return AnnouncementDisplayStateNone;
    }
}

- (void)markAnnouncementAsShown:(AnnouncementModel *)announcement {
    if (!announcement) return;
    self.shownAnnouncements[announcement.announcement_uuid] = @(YES);
    [self saveData];
}

- (void)fetchLatestAnnouncementWithCompletion:(void(^_Nullable)(AnnouncementModel * _Nullable announcement, NSError * _Nullable error))completion {
    NSDictionary *params = @{
        @"action": @"getActiveAnnouncement"
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                               modules:@"announcement"
                                            parameters:params
                                              progress:nil
                                               success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code != 200) {
                NSError *error = [NSError errorWithDomain:@"AnnouncementManager" code:code userInfo:@{NSLocalizedDescriptionKey: jsonResult[@"msg"] ?: @"获取公告失败"}];
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            NSDictionary *data = jsonResult[@"data"];
            if (!data || [data isKindOfClass:[NSNull class]]) {
                if (completion) {
                    completion(nil, nil);
                }
                return;
            }
            NSLog(@"读取最新激活公告：%@",data);
            AnnouncementModel *announcement = [AnnouncementModel yy_modelWithDictionary:data[@"announcement"]];
            self.latestAnnouncement = announcement;
            NSLog(@"广告弹窗模式：%ld",announcement.announcement_popup_mode);
            [self saveData];
            
            if (completion) {
                completion(announcement, nil);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, error);
            }
        });
    }];
}

- (void)showAnnouncementIfNeededFromViewController:(UIViewController *)viewController {
    if (!viewController) return;
    
    [self fetchLatestAnnouncementWithCompletion:^(AnnouncementModel * _Nullable announcement, NSError * _Nullable error) {
        if (error) {
            NSLog(@"获取公告失败: %@", error);
            return;
        }
        
        if (!announcement) {
            NSLog(@"没有需要显示的公告");
            return;
        }
        
        AnnouncementDisplayState displayState = [self shouldDisplayAnnouncement:announcement];
        if (displayState == AnnouncementDisplayStateNone) {
            NSLog(@"公告不需要显示");
            return;
        }
        
        [self showAnnouncement:announcement fromViewController:viewController];
    }];
}

- (void)showAnnouncement:(AnnouncementModel *)announcement fromViewController:(UIViewController *)viewController {
    if (!announcement || !viewController) return;
    
    [self markAnnouncementAsShown:announcement];
    
    __weak typeof(viewController) weakVC = viewController;
    [CustomDialogView showWithTitle:announcement.announcement_title
                           subtitle:announcement.announcement_content
                        buttonTitle:@"查看详情"
                           bottomTip:@"查看更多公告"
                       buttonAction:^{
                           [self showAnnouncementDetail:announcement fromViewController:weakVC];
                       }
                    bottomTipAction:^{
                           [self showAnnouncementList:weakVC];
                       }];
}

- (void)showAnnouncementDetail:(AnnouncementModel *)announcement fromViewController:(UIViewController *)viewController {
    if (!announcement || !viewController) return;
    
    AnnouncementDetailViewController *detailVC = [[AnnouncementDetailViewController alloc] init];
    detailVC.announcementUuid = announcement.announcement_uuid;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [viewController presentViewController:navVC animated:YES completion:nil];
}

- (void)showAnnouncementList:(UIViewController *)viewController {
    if (!viewController) return;
    
    AnnouncementListViewController *listVC = [[AnnouncementListViewController alloc] init];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:listVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [viewController presentViewController:navVC animated:YES completion:nil];
}

- (void)clearDisplayHistory {
    [self.shownAnnouncements removeAllObjects];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kShownAnnouncementsKey];
    [defaults synchronize];
}

@end
