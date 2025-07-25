//
//  AppIconViewCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import "AppFileCell.h"
#import "NewAppFileModel.h"

@interface AppFileCell ()

//图片背景父视图
@property (nonatomic, strong) UIStackView *fileStackView;

@property (nonatomic, strong) NewAppFileModel*appFileModel;

@property (nonatomic, assign) CGFloat maxWidth;
@end

@implementation AppFileCell


- (void)setupUI {
    
    // 设置背景色
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
    ];
    self.contentView.layer.cornerRadius = 15;
    
    
    // 应用图标
    self.fileStackView = [[UIStackView alloc] init];
    
    
    // 添加子视图
    [self.contentView addSubview:self.fileStackView];
    
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.maxWidth = kWidth - 32;
    // 统计信息按钮约束
    [self.fileStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-16);
    }];
    
    
}

/* 文件类型枚举
typedef NS_ENUM(NSInteger, FileType) {
    FileTypeIpa      = 0,  ///< iOS应用安装包文件(.ipa)
    FileTypeDeb      = 1,  ///< Debian软件包文件(.deb)
    FileTypeZip      = 2,  ///< ZIP压缩文件(.zip)
    FileTypeJson     = 3,  ///< JSON数据文件(.json)
    FileTypeJs       = 4,  ///< JavaScript脚本文件(.js)
    FileTypeHtml     = 5,  ///< HTML网页文件(.html)
    FileTypeDylib    = 6,  ///< 动态链接库文件(.dylib)
    FileTypePlist    = 7,  ///< 属性列表文件(.plist)
    FileTypeOther    = 8,  ///< 其他文件类型
};
*/
- (void)bindViewModel:(id)viewModel {
    self.appFileModel = (NewAppFileModel*)viewModel;
//    switch (self.appFileModel.file_type) {
//        case 1:
//            
//            break;
//            
//        default:
//            
//            break;
//    }
}
#pragma mark - 更新后的HXPhotoManager配置


@end
