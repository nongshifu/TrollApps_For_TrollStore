//
//  RunInBackground.m
//  libIntegrity
//
//  Created by niu_o0 on 2020/4/24.
//  Copyright © 2020 niu_o0. All rights reserved.
//

#import "RunInBackground.h"
#import <UIKit/UIKit.h>
#import "blank.h"
#import "RunInBackground.h"
#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RunInBackground ()

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) float Oldvolume;
@property (nonatomic, assign) BOOL wuzhikaiguan;
@end

@implementation RunInBackground

+ (void)load {
    [RunInBackground sharedBg];
}

+ (instancetype)sharedBg {
    static RunInBackground *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RunInBackground alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 监听进入后台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        // 监听将进入前台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)didEnterBackground {
    NSLog(@"进入后台");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSData *audioData = blank(); // 调用包含音频数据的函数 blank() 获取音频数据
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
    self.audioPlayer.numberOfLoops = -1;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    // 创建定时器，每隔30秒重新播放音频
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(repeatPlay) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)willEnterForeground {
    NSLog(@"进入前台");
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    
    // 停止定时器
    [self.timer invalidate];
    self.timer = nil;
}

- (void)repeatPlay {
    // 检查音频是否正在播放，如果已经停止则重新播放
    if (!self.audioPlayer.isPlaying) {
        [self.audioPlayer play];
    }
    
    // 获取当前系统音量
    float volume = [[AVAudioSession sharedInstance] outputVolume];
    if (volume != self.Oldvolume) {
        NSLog(@"当前音量：%f", volume);
        self.Oldvolume = volume;
        self.wuzhikaiguan = !self.wuzhikaiguan;
        [[NSUserDefaults standardUserDefaults] setBool:self.wuzhikaiguan forKey:@"wzkg"];
    }
}



@end
