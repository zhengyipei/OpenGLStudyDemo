//
//  ZYPContainerView.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/21.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPContainerView.h"
#import <AVFoundation/AVFoundation.h>
#import "ZYPGLView.h"

@interface ZYPContainerView()

@property (nonatomic,strong) ZYPGLView *glView;

@end

@implementation ZYPContainerView

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setupGLView];
}

- (void)setupGLView {
    
    self.glView = [[ZYPGLView alloc]initWithFrame:self.bounds];
    [self addSubview:self.glView];
}
#pragma mark - *** private
- (void)layoutGLKView {
    
    CGSize imageSize = self.image.size;
    
    //Returns a scaled CGRect that maintains the aspect ratio specified by a CGSize within a bounding CGRect.
    //返回一个在Self.bounds范围的CGRect,根据imagaSize的一个纵横比
    CGRect frame = AVMakeRectWithAspectRatioInsideRect(imageSize, self.bounds);
    
    self.glView.frame = frame;
    
    self.glView.contentScaleFactor = imageSize.width / frame.size.width;
    
}

#pragma mark - *** public
- (void)setImage:(UIImage *)image {
    _image = image;
    
    [self layoutGLKView];
    
    [self.glView layoutGLViewWithImage:_image];
}

- (void)setColorTempValue:(CGFloat)colorTempValue{
    _colorTempValue = colorTempValue;
    self.glView.temperature = colorTempValue;
}
- (void)setSaturationValue:(CGFloat)saturationValue{
    _saturationValue = saturationValue;
    self.glView.saturation = saturationValue;
}


@end
