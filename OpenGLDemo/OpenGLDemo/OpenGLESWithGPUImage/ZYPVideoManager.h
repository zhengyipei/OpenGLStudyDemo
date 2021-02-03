//
//  ZYPVideoManager.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/28.
//  Copyright © 2021 imac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZYPGPUImageBeautifyFilter.h"
#import <GPUImage/GPUImage.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZYPVideoManagerCameraType){
    ZYPVideoManagerCameraTypeFront = 0,
    ZYPVideoManagerCameraTypeBack,
};

@protocol ZYPVideoManagerProtocol <NSObject>
//开始录制
- (void)didStartRecordVideo;
//视频压缩
- (void)didCompressingVideo;
//结束录制
- (void)didEndRecordVideoWithTime:(CGFloat)totalTime outputFile:(NSString*)filePath;

@end

@interface ZYPVideoManager : NSObject

@property (nonatomic,weak) id<ZYPVideoManagerProtocol> delegate;

@property (nonatomic,assign) CGRect frame;

@property (nonatomic,assign) CGFloat maxTime;

@property (nonatomic,assign,readonly) ZYPVideoManagerCameraType cameraType;

+ (instancetype)manager;
/**
 加载到显示的视图上
 @param frame  父视图中的frame
 @param superView 父视图
 */
- (void)showWithFrame:(CGRect)frame superView:(UIView*)superView;

- (void)startRecording;

- (void)endRecording;

- (void)pauseRecording;

- (void)resumeRecording;
//切换摄像头
- (void)changeCameraPosition:(ZYPVideoManagerCameraType)type;
//打开闪光灯
- (void)turnTorchOn:(BOOL)on;

@end

NS_ASSUME_NONNULL_END
