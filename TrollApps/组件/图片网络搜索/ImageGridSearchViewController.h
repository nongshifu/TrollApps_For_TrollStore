//
//  ImageGridSearchViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/23.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ImageModel.h"
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@class ImageGridSearchViewController;

@protocol ImageGridSearchViewControllerDelegate <NSObject>
// 点击图片回调（返回图片对象和URL）
- (void)imageGridSearch:(ImageGridSearchViewController *)controller didSelectImage:(ImageModel *)imageModel cell:(UICollectionViewCell*)cell;
/// 确认按钮点击后调用代理
- (void)imageGridSearch:(ImageGridSearchViewController *)controller didSelectImages:(NSArray<ImageModel *> *)imageModels;
@end

@interface ImageGridSearchViewController : UIViewController

@property (nonatomic, copy) NSString *searchKeyword; // 初始搜索关键词
@property (nonatomic, weak) id<ImageGridSearchViewControllerDelegate> delegate;
///最大选择数量 默认0 不限制
@property (nonatomic, assign) NSInteger maxiMum;

// 替换原来的NSMutableArray<NSDictionary *>
@property (nonatomic, strong) NSMutableArray<ImageModel *> *selectedImages;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedUrlSet; // 用于快速判断是否选中（通过url去重）

+ (instancetype)sharedInstance;
@end


NS_ASSUME_NONNULL_END
