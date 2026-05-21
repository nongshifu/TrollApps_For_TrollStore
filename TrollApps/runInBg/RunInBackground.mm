#import "RunInBackground.h"
#import "blank.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface RunInBackground () <CLLocationManagerDelegate>
@property (nonatomic, strong) AVAudioPlayer *silencePlayer;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSTimer *networkTimer;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation RunInBackground

static RunInBackground *instance = nil;

+ (void)load {
//    [RunInBackground startBackgroundService]; // 启动三合一保活
}


+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// 启动三合一保活
+ (void)startBackgroundService {
    [[self sharedInstance] startAllServices];
}

// 停止
+ (void)stopBackgroundService {
    [[self sharedInstance] stopAllServices];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupNotifications];
    }
    return self;
}

// 监听前后台
- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

// 启动所有保活服务
- (void)startAllServices {
    [self setupSilentAudio];    // 1. 低冲突静默音频
    [self setupLocation];       // 2. 后台定位（最稳定）
    [self setupNetworkTimer];   // 3. 网络心跳
    [self beginBackgroundTask]; // 4. 后台任务延长
}

// 停止所有
- (void)stopAllServices {
    [self stopSilentAudio];
    [self stopLocation];
    [self stopNetworkTimer];
    [self endBackgroundTask];
}

#pragma mark - 1. 低冲突静默音频（解决和其他播放器冲突）
- (void)setupSilentAudio {
    // 关键：用 AVAudioSessionCategoryAmbient 不会打断其他音乐！
    NSError *sessionError;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    // 空白音频数据（1秒静音）
   
    NSData *audioData = blank();
    if(!audioData){
        audioData = [self getSilenceAudioData];
    }
    self.silencePlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
    self.silencePlayer.numberOfLoops = -1;
    self.silencePlayer.volume = 0.01; // 几乎无声
    [self.silencePlayer prepareToPlay];
    [self.silencePlayer play];
}

- (void)stopSilentAudio {
    [self.silencePlayer stop];
    self.silencePlayer = nil;
}

// 生成静音音频数据
- (NSData *)getSilenceAudioData {
    NSMutableData *data = [NSMutableData data];
    int16_t mute = 0;
    for (int i = 0; i < 8000; i++) {
        [data appendBytes:&mute length:2];
    }
    return data;
}

#pragma mark - 2. 后台定位保活（核心稳定保活）
- (void)setupLocation {
    if (![CLLocationManager locationServicesEnabled]) return;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers; // 低精度省电
    self.locationManager.distanceFilter = 500; // 500米更新一次
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    // 申请定位权限
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocation {
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"后台定位更新：%@", locations.lastObject);
}

#pragma mark - 3. 网络心跳保活
- (void)setupNetworkTimer {
    if (self.networkTimer) return;
    self.networkTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                        target:self
                                                      selector:@selector(networkHeartBeat)
                                                      userInfo:nil
                                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.networkTimer forMode:NSRunLoopCommonModes];
}

- (void)stopNetworkTimer {
    [self.networkTimer invalidate];
    self.networkTimer = nil;
}

// 网络心跳（空请求即可）
- (void)networkHeartBeat {
    NSLog(@"后台网络心跳");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 简单网络检测，不消耗流量
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "www.baidu.com");
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
    });
}

#pragma mark - 4. 后台任务延长
- (void)beginBackgroundTask {
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - 系统通知
- (void)appDidEnterBackground {
    NSLog(@"APP 进入后台，启动三合一保活");
    [self beginBackgroundTask];
}

- (void)appWillEnterForeground {
    NSLog(@"APP 回到前台");
}

@end
