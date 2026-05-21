#import "FileListCell.h"
#import <AVFoundation/AVFoundation.h>

@interface FileListCell ()
@property (nonatomic, strong, readwrite) UIImageView *fileIconView;
@property (nonatomic, strong, readwrite) UILabel *fileNameLabel;
@property (nonatomic, strong, readwrite) UILabel *fileSizeLabel;
@property (nonatomic, strong, readwrite) UILabel *detailLabel;
@property (nonatomic, strong, readwrite) UILabel *remarkLabel;
@property (nonatomic, strong, readwrite) UIButton *checkButton;
@property (nonatomic, strong, readwrite) UIButton *actionButton;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) FileModel *currentModel;
@end

@implementation FileListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.containerView];

    self.fileIconView = [[UIImageView alloc] init];
    self.fileIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.fileIconView];

    self.fileNameLabel = [[UILabel alloc] init];
    self.fileNameLabel.font = [UIFont systemFontOfSize:16];
    self.fileNameLabel.textColor = [UIColor labelColor];
    self.fileNameLabel.numberOfLines = 1;
    [self.containerView addSubview:self.fileNameLabel];

    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.font = [UIFont systemFontOfSize:10];
    self.detailLabel.textColor = [UIColor secondaryLabelColor];
    self.detailLabel.numberOfLines = 1;
    [self.containerView addSubview:self.detailLabel];

    self.remarkLabel = [[UILabel alloc] init];
    self.remarkLabel.font = [UIFont systemFontOfSize:11];
    self.remarkLabel.textColor = [UIColor systemOrangeColor];
    self.remarkLabel.numberOfLines = 1;
    [self.containerView addSubview:self.remarkLabel];

    self.checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.checkButton setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
    [self.checkButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
    self.checkButton.hidden = YES;
    [self.checkButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.checkButton];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:[UIImage systemImageNamed:@"ellipsis.circle"] forState:UIControlStateNormal];
    self.actionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.actionButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.actionButton];

    self.isBatchEditing = NO;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.containerView.frame = self.contentView.bounds;

    CGFloat height = self.contentView.bounds.size.height;
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat actionButtonWidth = 44;
    CGFloat leftPadding = 15;
    CGFloat iconSize = 32;

    if (self.isBatchEditing) {
        self.checkButton.frame = CGRectMake(10, (height - 24) / 2, 24, 24);
        self.actionButton.frame = CGRectMake(width - actionButtonWidth, (height - actionButtonWidth) / 2, actionButtonWidth, actionButtonWidth);
        self.fileIconView.frame = CGRectMake(44, (height - iconSize) / 2, iconSize, iconSize);
        if (self.remarkLabel.text.length > 0) {
            self.fileNameLabel.frame = CGRectMake(86, 6, width - 86 - actionButtonWidth - 10, 16);
            self.remarkLabel.frame = CGRectMake(86, 24, width - 86 - actionButtonWidth - 10, 14);
            self.detailLabel.frame = CGRectMake(86, height - 16, width - 86 - actionButtonWidth - 10, 14);
        } else {
            self.fileNameLabel.frame = CGRectMake(86, (height / 2) - 18, width - 86 - actionButtonWidth - 10, 18);
            self.detailLabel.frame = CGRectMake(86, (height / 2) + 2, width - 86 - actionButtonWidth - 10, 14);
            self.remarkLabel.frame = CGRectMake(86, (height / 2) + 2, 0, 0);
        }
    } else {
        self.checkButton.frame = CGRectMake(-44, 0, 0, 0);
        self.actionButton.frame = CGRectMake(width - actionButtonWidth, (height - actionButtonWidth) / 2, actionButtonWidth, actionButtonWidth);
        self.fileIconView.frame = CGRectMake(leftPadding, (height - iconSize) / 2, iconSize, iconSize);
        if (self.remarkLabel.text.length > 0) {
            self.fileNameLabel.frame = CGRectMake(leftPadding + iconSize + 10, 6, width - leftPadding - iconSize - actionButtonWidth - 20, 16);
            self.remarkLabel.frame = CGRectMake(leftPadding + iconSize + 10, 24, width - leftPadding - iconSize - actionButtonWidth - 20, 14);
            self.detailLabel.frame = CGRectMake(leftPadding + iconSize + 10, height - 16, width - leftPadding - iconSize - actionButtonWidth - 20, 14);
        } else {
            self.fileNameLabel.frame = CGRectMake(leftPadding + iconSize + 10, (height / 2) - 18, width - leftPadding - iconSize - actionButtonWidth - 20, 18);
            self.detailLabel.frame = CGRectMake(leftPadding + iconSize + 10, (height / 2) + 2, width - leftPadding - iconSize - actionButtonWidth - 20, 14);
            self.remarkLabel.frame = CGRectMake(leftPadding + iconSize + 10, (height / 2) + 2, 0, 0);
        }
    }
}

- (void)configWithFileModel:(FileModel *)model {
    self.currentModel = model;
    self.fileNameLabel.text = model.fileName;

    NSString *sizeStr = [model formattedFileSize];
    NSString *dateStr = [model formattedModificationDate];
    self.detailLabel.text = [NSString stringWithFormat:@"%@  %@", dateStr, sizeStr];

    // 设置备注
    self.remarkLabel.text = model.remark ?: @"";

    // 设置图标或缩略图
    if (model.itemType == FileItemTypeFolder) {
        self.fileIconView.image = [UIImage systemImageNamed:@"folder.fill"];
        self.fileIconView.contentMode = UIViewContentModeScaleAspectFit;
        self.fileIconView.clipsToBounds = NO;
    } else {
        // 尝试获取图片/视频缩略图
        UIImage *thumbnail = [self thumbnailForFile:model.filePath];
        if (thumbnail) {
            self.fileIconView.image = thumbnail;
            self.fileIconView.contentMode = UIViewContentModeScaleAspectFill;
            self.fileIconView.clipsToBounds = YES;
        } else {
            // 根据文件扩展名显示不同图标
            self.fileIconView.image = [self iconForFileExtension:model.filePath.pathExtension.lowercaseString];
            self.fileIconView.contentMode = UIViewContentModeScaleAspectFit;
            self.fileIconView.clipsToBounds = NO;
        }
    }

    if (model.isFavorite) {
        self.containerView.backgroundColor = [UIColor systemBackgroundColor];
        if (model.itemType == FileItemTypeFolder || !self.fileIconView.image) {
            self.fileIconView.tintColor = [UIColor systemOrangeColor];
        }
    } else {
        self.containerView.backgroundColor = [UIColor clearColor];
        if (model.itemType == FileItemTypeFolder || !self.fileIconView.image) {
            if (model.itemType == FileItemTypeFolder) {
                self.fileIconView.tintColor = [UIColor systemBlueColor];
            } else {
                self.fileIconView.tintColor = [UIColor systemGrayColor];
            }
        }
    }

    self.checkButton.selected = model.isSelected;
    self.checkButton.hidden = !self.isBatchEditing;
    self.actionButton.hidden = self.isBatchEditing;
    
    [self setNeedsLayout];
}

- (UIImage *)iconForFileExtension:(NSString *)extension {
    // 音频文件
    NSArray *audioExtensions = @[@"mp3", @"wav", @"flac", @"aac", @"ogg", @"m4a", @"wma", @"aiff"];
    if ([audioExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"music.note"];
    }
    
    // 压缩文件
    NSArray *archiveExtensions = @[@"zip", @"rar", @"7z", @"tar", @"gz", @"bz2", @"xz", @"lzh"];
    if ([archiveExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"doc.zipper"];
    }
    
    // 文档文件
    NSArray *docExtensions = @[@"pdf", @"doc", @"docx", @"txt", @"rtf", @"pages", @"numbers", @"keynote", @"ppt", @"pptx", @"xls", @"xlsx", @"csv"];
    if ([docExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"doc.text"];
    }
    
    // 代码文件
    NSArray *codeExtensions = @[@"h", @"m", @"swift", @"c", @"cpp", @"java", @"py", @"js", @"html", @"css", @"xml", @"json", @"plist"];
    if ([codeExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"chevron.left.forwardslash.chevron.right"];
    }
    
    // 可执行文件
    NSArray *executableExtensions = @[@"app", @"exe", @"dmg", @"pkg", @"deb", @"rpm"];
    if ([executableExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"app.fill"];
    }
    
    // 默认文档图标
    return [UIImage systemImageNamed:@"doc.fill"];
}

- (UIImage *)thumbnailForFile:(NSString *)filePath {
    NSString *extension = [filePath pathExtension].lowercaseString;
    
    // 图片类型
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"heic", @"heif"];
    if ([imageExtensions containsObject:extension]) {
        return [UIImage imageWithContentsOfFile:filePath];
    }
    
    // 视频类型 - 获取第一帧
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"m4v", @"wmv", @"flv"];
    if ([videoExtensions containsObject:extension]) {
        return [self thumbnailForVideo:filePath];
    }
    
    return nil;
}

- (UIImage *)thumbnailForVideo:(NSString *)videoPath {
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    NSError *error = nil;
    CMTime time = CMTimeMakeWithSeconds(0, 60);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    
    if (imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return image;
    }
    
    return nil;
}

- (void)checkButtonTapped:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.currentModel.isSelected = sender.selected;

    if ([self.cellDelegate respondsToSelector:@selector(fileListCell:didSelectCheckBox:forFileModel:)]) {
        [self.cellDelegate fileListCell:self didSelectCheckBox:sender.selected forFileModel:self.currentModel];
    }
}

- (void)actionButtonTapped:(UIButton *)sender {
    if ([self.cellDelegate respondsToSelector:@selector(fileListCell:didTapActionButtonForFileModel:)]) {
        [self.cellDelegate fileListCell:self didTapActionButtonForFileModel:self.currentModel];
    }
}

- (void)setIsBatchEditing:(BOOL)isBatchEditing {
    _isBatchEditing = isBatchEditing;
    self.checkButton.hidden = !isBatchEditing;
    self.actionButton.hidden = isBatchEditing;
    [self setNeedsLayout];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.fileIconView.image = nil;
    self.fileNameLabel.text = nil;
    self.fileSizeLabel.text = nil;
    self.detailLabel.text = nil;
    self.remarkLabel.text = nil;
    self.checkButton.selected = NO;
    self.containerView.backgroundColor = [UIColor clearColor];
}

@end
