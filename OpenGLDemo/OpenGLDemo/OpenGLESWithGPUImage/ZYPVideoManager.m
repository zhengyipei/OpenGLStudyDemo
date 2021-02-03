//
//  ZYPVideoManager.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/28.
//  Copyright © 2021 imac. All rights reserved.
//


#define COMPRESSEDVIDEOPATH [NSHomeDirectory() stringByAppendingFormat:@"/Documents/CompressionVideoField"]

#import "ZYPVideoManager.h"

@interface ZYPVideoManager()<GPUImageVideoCameraDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//摄像头
@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;
//美颜滤镜
@property (nonatomic,strong) ZYPGPUImageBeautifyFilter *beautifyFilter;
//饱和度滤镜
@property (nonatomic,strong) GPUImageSaturationFilter *saturationFilter;
//视频输出视图
@property (nonatomic,strong) GPUImageView *displayView;
//视频写入
@property (nonatomic,strong) GPUImageMovieWriter *movieWirter;
//视频写入地址url
@property (nonatomic,strong) NSURL *movieURL;
//视频写入路径
@property (nonatomic,copy) NSString *moviePath;
//压缩成功后的视频路径
@property (nonatomic,copy) NSString *resultPath;
//视频时长
@property (nonatomic,assign) int seconds;
//系统计时器
@property (nonatomic,strong) NSTimer *timer;
//计时器常量
@property (nonatomic,assign) int recordSecond;

@property (nonatomic,assign) BOOL isRunning;

@end

@implementation ZYPVideoManager

@synthesize cameraType = _cameraType;

static ZYPVideoManager *_manager;

+(instancetype)manager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[ZYPVideoManager alloc]init];
    });
    return _manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manager == nil) {
            _manager = [super allocWithZone:zone];
        }
    });
    return _manager;
}

- (void)startRecording{
    NSString *defultPath = [self getVideoPathCache];
    self.moviePath = [defultPath stringByAppendingPathComponent:[self getVideoNameWithType:@"mp4"]];
    self.movieURL = [NSURL fileURLWithPath:self.moviePath];
    //删除文件
    unlink([self.moviePath UTF8String]);
    
    self.movieWirter = [[GPUImageMovieWriter alloc]initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 640.0)];
    self.movieWirter.encodingLiveVideo = YES;
    self.movieWirter.shouldPassthroughAudio  = YES;
    self.movieWirter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
    
    [self.beautifyFilter addTarget:self.movieWirter];
    [self.saturationFilter addTarget:self.movieWirter];
    
    self.videoCamera.audioEncodingTarget = self.movieWirter;
    
    [self.movieWirter startRecording];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartRecordVideo)]) {
        [self.delegate didStartRecordVideo];
    }
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
    self.isRunning = YES;
}

- (void)endRecording{
    if (self.isRunning) {
        self.isRunning = NO;
        [self.timer invalidate];
        self.timer = nil;
        __weak typeof(self) weakSelf = self;
        
        [self.movieWirter finishRecording];
        
        [self.saturationFilter removeTarget:self.movieWirter];
        self.videoCamera.audioEncodingTarget = nil;
        if (self.recordSecond > self.maxTime) {
            
        }else{
            if ([self.delegate respondsToSelector:@selector(didCompressingVideo)]) {
                [self.delegate didCompressingVideo];
            }
            [self compressVideoWithUrl:self.movieURL compressionType:AVAssetExportPresetMediumQuality filePath:^(NSString *resultPath, float memorySize, NSString *videoImagePath, int seconds) {
//                NSData *data = [NSData dataWithContentsOfFile:resultPath];
//                CGFloat totalSize = (CGFloat)data.length / 1024 / 1024;
                if ([weakSelf.delegate respondsToSelector:@selector(didEndRecordVideoWithTime:outputFile:)]) {
                    [weakSelf.delegate didEndRecordVideoWithTime:seconds outputFile:resultPath];
                }
            }];
        }
    }
}

- (void)pauseRecording{
    if (self.isRunning) {
        self.isRunning = NO;
        [self.timer invalidate];
        self.timer = nil;
        [_videoCamera pauseCameraCapture];
    }
}
- (void)resumeRecording{
    self.isRunning = YES;
    [_videoCamera resumeCameraCapture];
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
}

#pragma mark - *** 摄像头输出代理方法
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
}
#pragma mark - *** 自定义方法
- (void)showWithFrame:(CGRect)frame superView:(UIView *)superView{
    _frame = frame;
    
    [self.saturationFilter addTarget:self.displayView];
    [self.videoCamera addTarget:self.saturationFilter];
    
    [self.videoCamera addTarget:self.beautifyFilter];
    [self.beautifyFilter addTarget:self.displayView];
    
    [superView addSubview:self.displayView];
    [self.videoCamera startCameraCapture];
}
//切换前后摄像头
- (void)changeCameraPosition:(ZYPVideoManagerCameraType)type{
    _cameraType = type;
    switch (type) {
        case ZYPVideoManagerCameraTypeFront:
            [_videoCamera rotateCamera];
            break;
        case ZYPVideoManagerCameraTypeBack:
            [_videoCamera rotateCamera];
            break;
        default:
            break;
    }
}

// 手电筒开关
- (void)turnTorchOn:(BOOL)on{
    if ([_videoCamera.inputCamera hasTorch] && [_videoCamera.inputCamera hasFlash]) {
        [_videoCamera.inputCamera lockForConfiguration:nil];
        if (on) {
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
        }else{
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        }
        [_videoCamera.inputCamera unlockForConfiguration];
    }
}
//获取视频路径
- (NSString *)getVideoPathCache{
    NSString * videoCache = [NSTemporaryDirectory() stringByAppendingString:@"video"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!existed) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoCache;
}
//获取视频名称
- (NSString *)getVideoNameWithType:(NSString *)fileType {
    
    NSTimeInterval now  = [[NSDate date]timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *timeStr = [formatter stringFromDate:nowDate];
    NSString *fileName = [NSString stringWithFormat:@"video_@%@.%@",timeStr,fileType];
    return fileName;
}
- (void)updateWithTime{
    self.recordSecond++;
    if (self.recordSecond >= self.maxTime) {
        [self endRecording];
    }
}

- (void)compressVideoWithUrl:(NSURL *)url compressionType:(NSString*)type filePath:(void(^)(NSString *resultPath, float memorySize,NSString *videoImagePath,int seconds))resultBlock {
    NSString *resultPath;
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    CGFloat totalSize = (float)data.length / 1024 / 1024;
    NSLog(@"压缩前大小：%.2fM",totalSize);
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    CMTime time = [avAsset duration];
    
    int seconds = ceil(time.value / time.timescale);
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:type]) {
        /*   创建AVAssetExportSession对象
             压缩的质量
             AVAssetExportPresetLowQuality   最low的画质最好不要选择实在是看不清楚
             AVAssetExportPresetMediumQuality  使用到压缩的话都说用这个
             AVAssetExportPresetHighestQuality  最清晰的画质

        */
        AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        NSDateFormatter *formater = [[NSDateFormatter alloc]init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isExist = [manager fileExistsAtPath:COMPRESSEDVIDEOPATH];
        if (!isExist) {
            [manager createDirectoryAtPath:COMPRESSEDVIDEOPATH withIntermediateDirectories:YES attributes:nil error:nil];
        }
        resultPath = [COMPRESSEDVIDEOPATH stringByAppendingPathComponent:[NSString stringWithFormat:@"user%outputVideo-%@.mp4",arc4random_uniform(10000),[formater stringFromDate:[NSDate date]]]];
        
        session.outputURL = [NSURL fileURLWithPath:resultPath];
        session.outputFileType = AVFileTypeMPEG4;
        session.shouldOptimizeForNetworkUse = YES;
        [session exportAsynchronouslyWithCompletionHandler:^{
            switch (session.status) {
//                case AVAssetExportSessionStatusUnknown:
//                    break;
//                case AVAssetExportSessionStatusWaiting:
//                    break;
//                case AVAssetExportSessionStatusExporting:
//                    break;
//                case AVAssetExportSessionStatusCancelled:
//                    break;
//                case AVAssetExportSessionStatusFailed:
//                    break;
                case AVAssetExportSessionStatusCompleted:{
                    NSData * data = [NSData dataWithContentsOfFile:resultPath];
                    float compressedSize = (float)data.length / 1024 /1024;
                    resultBlock?resultBlock(resultPath,compressedSize,@"",seconds):nil;
                    NSLog(@"压缩后大小：%.2f",compressedSize);
                    break;
                }
                default:
                    break;
            }
        }];
    }
}

- (void)dealloc{
    [self.timer invalidate];
    NSLog(@"销毁了");
}

#pragma mark - *** 懒加载
- (GPUImageVideoCamera *)videoCamera {
    if (_videoCamera == nil) {
        _videoCamera  = [[GPUImageVideoCamera alloc]initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.delegate = self;
        [_videoCamera addAudioInputsAndOutputs];
    }
    return _videoCamera;
}
- (ZYPGPUImageBeautifyFilter *)beautifyFilter{
    if (!_beautifyFilter) {
        _beautifyFilter = [[ZYPGPUImageBeautifyFilter alloc]init];
    }
    return _beautifyFilter;
}
- (GPUImageSaturationFilter *)saturationFilter{
    if (!_saturationFilter) {
        _saturationFilter = [[GPUImageSaturationFilter alloc]init];
        _saturationFilter.saturation = 2.0;
    }
    return _saturationFilter;
}
- (GPUImageView *)displayView{
    if (!_displayView) {
        _displayView = [[GPUImageView alloc]initWithFrame:self.frame];
        _displayView.fillMode = kGPUImageFillModePreserveAspectRatio;
    }
    return _displayView;
}
- (NSTimer *)timer{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWithTime) userInfo:nil repeats:YES];
    }
    return _timer;
}
@end
