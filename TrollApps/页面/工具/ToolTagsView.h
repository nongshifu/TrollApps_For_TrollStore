//
//  ToolTagsView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ToolTagsViewDelegate <NSObject>
@optional
- (void)toolTagsViewDidChangeTags:(id)tagsView;
@end

@interface ToolTagsView : UIView

@property (nonatomic, weak) id<ToolTagsViewDelegate> toolTagsDelegate;

- (void)setTags:(NSArray *)tags;
- (NSArray *)getTags;
- (void)addTag:(NSString *)tag;

@end


NS_ASSUME_NONNULL_END
