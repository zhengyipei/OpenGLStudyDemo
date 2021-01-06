//
//  ZYPDrawingBoardView.h
//  OpenGLDemo
//
//  Created by imac on 2020/12/14.
//  Copyright © 2020 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYPPoint : UIView

//屏幕上的点（x,y）
@property (nonatomic , strong) NSNumber* mY;
@property (nonatomic , strong) NSNumber* mX;

@end

@interface ZYPDrawingBoardView : UIView

//location 最新的点
@property(nonatomic, readwrite) CGPoint location;
//previousLocation 前一个点
@property(nonatomic, readwrite) CGPoint previousLocation;

//清屏
- (void)erase;

//设置画笔颜色
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

//绘制
- (void)paint;


@end

NS_ASSUME_NONNULL_END
