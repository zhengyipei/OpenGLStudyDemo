//
//  ZYPOpenGLESWithGPUImageViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/28.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPOpenGLESWithGPUImageViewController.h"
#import <GPUImageView.h>
#import <GPUImage/GPUImage.h>

@interface ZYPOpenGLESWithGPUImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *targetImage;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) GPUImageSaturationFilter *saturationFilter;
@end

@implementation ZYPOpenGLESWithGPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.image = [UIImage imageNamed:@"face"];
    self.targetImage.image = self.image;
}

- (IBAction)saturationAction:(UISlider *)sender {
//    self.saturationFilter.saturation = 1.0;
    [self.saturationFilter forceProcessingAtSize:self.image.size];
    [self.saturationFilter useNextFrameForImageCapture];
    self.saturationFilter.saturation = sender.value;
    GPUImagePicture *stillImageSoucer = [[GPUImagePicture alloc]initWithImage:self.image];
    [stillImageSoucer addTarget:self.saturationFilter];
    [stillImageSoucer processImage];
    self.targetImage.image = [self.saturationFilter imageFromCurrentFramebuffer];
}


- (GPUImageSaturationFilter *)saturationFilter{
    if (!_saturationFilter) {
        _saturationFilter = [[GPUImageSaturationFilter alloc]init];
        _saturationFilter.saturation = 1.0;
    }
    return _saturationFilter;
}

@end
