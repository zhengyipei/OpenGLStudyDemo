//
//  ZYPContainerView.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/21.
//  Copyright © 2021 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYPContainerView : UIView

//图片
@property (nonatomic, strong) UIImage *image;
//色温值
@property (nonatomic, assign) CGFloat  colorTempValue;
//饱和度
@property (nonatomic, assign) CGFloat  saturationValue;

@end

NS_ASSUME_NONNULL_END
