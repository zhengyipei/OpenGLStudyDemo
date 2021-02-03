//
//  ZYPRecordVideoWithGPUImageViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/28.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPRecordVideoWithGPUImageViewController.h"
#import <AVKit/AVKit.h>
#import "ZYPVideoManager.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

@interface ZYPRecordVideoWithGPUImageViewController ()<ZYPVideoManagerProtocol>
{
    NSString *_filePath;
}

@property (nonatomic,strong) UIView *videoView;

@property (nonatomic,strong) AVPlayerViewController *player;

@property (nonatomic,strong) ZYPVideoManager *videoManager;

@end

@implementation ZYPRecordVideoWithGPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
}

- (void)setupUI{
    self.navigationItem.title = @"录制视频";
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 64, screenWidth/2, 44);
    btn.backgroundColor = [UIColor yellowColor];
    [btn setTitle:@"录制视频" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *stop = [UIButton buttonWithType:UIButtonTypeCustom];
    stop.backgroundColor = [UIColor redColor];
    [stop setTitle:@"停止录制" forState:UIControlStateNormal];
    [stop setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    stop.frame = CGRectMake(screenWidth/2, 64, screenWidth/2, 44);
    [stop addTarget:self action:@selector(endRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stop];
    
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(10, screenHeight/2, screenWidth-20, screenHeight/2)];
    self.videoView.userInteractionEnabled = YES;
    
    UIButton *play = [UIButton buttonWithType:UIButtonTypeCustom];
    play.frame = CGRectMake(0, screenHeight-60, screenWidth, 50);
    [play setTitle:@"播放" forState:UIControlStateNormal];
    [play setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    
    self.videoManager = [[ZYPVideoManager alloc] init];
    self.videoManager.delegate = self;
    [self.videoManager showWithFrame:CGRectMake(20, 120, screenWidth-40, screenHeight/2-1) superView:self.view];
    self.videoManager.maxTime = 30.0;
    
}
-(void)recordBtnAction:(UIButton *)btn {
    if (self.videoManager.cameraType == ZYPVideoManagerCameraTypeFront) {
        [self.videoManager changeCameraPosition:ZYPVideoManagerCameraTypeBack];
    }else{
        [self.videoManager changeCameraPosition:ZYPVideoManagerCameraTypeFront];
    }
    
    [self.videoManager startRecording];
    
}

-(void)endRecording {
    
    [self.videoManager endRecording];
}

-(void)playVideo {
    if (_filePath.length==0) {
        return;
    }
    _player = [[AVPlayerViewController alloc] init];
    _player.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    _player.videoGravity = AVLayerVideoGravityResize;
    [self presentViewController:_player animated:NO completion:nil];
    
}

-(void)didStartRecordVideo {
    
//    [self.view addSubview:[CCNoticeLabel message:@"开始录制..." delaySecond:2]];
}

-(void)didCompressingVideo {
    
//    [self.view addSubview:[CCNoticeLabel message:@"视频压缩中..." delaySecond:2]];
    
}

-(void)didEndRecordVideoWithTime:(CGFloat)totalTime outputFile:(NSString *)filePath {
    
//    [self.view addSubview:[CCNoticeLabel message:@" 录制完毕，时长:%lu  路径：%@" delaySecond:4]];
    _filePath = filePath;
    
}

- (void)dealloc
{
    NSLog(@"控制器销毁了");
}


@end
