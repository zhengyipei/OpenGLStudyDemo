//
//  ZYPTakePhotoWithGPUImageViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/2/1.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPTakePhotoWithGPUImageViewController.h"
#import <GPUImage/GPUImage.h>
#import "ZYPGPUImageBeautifyFilter.h"


@interface ZYPTakePhotoWithGPUImageViewController ()

@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic,strong) GPUImageView *filterView;
@property (nonatomic,strong) UIButton *beautifyBtn;

@end

@implementation ZYPTakePhotoWithGPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
