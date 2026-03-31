//
//  DocumentPickerViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/13.
//

#import "DocumentPickerViewController.h"
#import "config.h"
@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    //遍历 获得文件列表视图 往下移动
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    
}

@end
