//
//  ZYPGLView.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/21.
//  Copyright © 2021 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYPGLView : UIView

@property (nonatomic,assign) CGFloat temperature;//色温
@property (nonatomic,assign) CGFloat saturation;//饱和度

- (void)layoutGLViewWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
