//
//  FileListCell.h
//  SandboxFileManager
//
//  文件列表单元格
//

#import <UIKit/UIKit.h>
#import "FileModel.h"
#import "FavoriteManager.h"
#import "FileSelectionManager.h"

@class FileListCell;

#pragma mark - FileListCellDelegate

/// 文件列表单元格代理协议
@protocol FileListCellDelegate <NSObject>

/// 勾选框状态改变时调用
/// @param cell 单元格
/// @param selected 是否选中
/// @param model 文件模型
- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model;

/// 点击操作按钮时调用
/// @param cell 单元格
/// @param model 文件模型
- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model;

@end

#pragma mark - FileListCell

/// 文件列表单元格
/// 显示文件名、详情、图标、勾选框等
@interface FileListCell : UITableViewCell

#pragma mark - 只读属性
@property (nonatomic, strong) FileModel *model;
/// 文件图标
@property (nonatomic, strong) UIImageView *fileIconView;

/// 文件名标签
@property (nonatomic, strong) UILabel *fileNameLabel;

/// 详情标签（显示大小、日期等）
@property (nonatomic, strong) UILabel *detailLabel;

/// 勾选按钮
@property (nonatomic, strong) UIButton *checkButton;

/// 操作按钮（播放、分享等）
@property (nonatomic, strong) UIButton *actionButton;

/// 文件大小
@property (nonatomic, strong) UILabel *fileSizeLabel;

/// 文件备注
@property (nonatomic, strong) UILabel *remarkLabel;

/// 卡片视图容器
@property (nonatomic, strong) UIView *containerView;

#pragma mark - 可写属性

/// 是否处于批量编辑模式
@property (nonatomic, assign) BOOL isBatchEditing;

/// 是否高亮显示（刚操作的文件）
@property (nonatomic, assign) BOOL isHighlightedFile;

/// 单元格代理
@property (nonatomic, assign) id<FileListCellDelegate> cellDelegate;

#pragma mark - 公共方法

/// 配置单元格显示
/// @param model 文件模型
- (void)configWithFileModel:(FileModel *)model;

@end
