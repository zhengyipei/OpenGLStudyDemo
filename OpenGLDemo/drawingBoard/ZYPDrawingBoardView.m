//
//  ZYPDrawingBoardView.m
//  OpenGLDemo
//
//  Created by imac on 2020/12/14.
//  Copyright © 2020 imac. All rights reserved.
//

#import "ZYPDrawingBoardView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>
#import "debug.h"
#import "shaderUtil.h"
#import "fileUtil.h"

//画笔透明度
#define kBrushOpacity        (1.0 / 2.0)
//画笔每一笔，有几个点！
#define kBrushPixelStep        2
//画笔的比例
#define kBrushScale            2

enum {
    PROGRAM_POINT, //0,
    NUM_PROGRAMS   //1,有几个程序
};


enum {
    UNIFORM_MVP,         //0
    UNIFORM_POINT_SIZE,  //1
    UNIFORM_VERTEX_COLOR,//2
    UNIFORM_TEXTURE,     //3
    NUM_UNIFORMS         //4
};

enum {
    ATTRIB_VERTEX, //0
    NUM_ATTRIBS//1
};

//定义一个结构体
typedef struct {
    //vert,frag 指向顶点、片元着色器程序文件
    char *vert, *frag;
    //创建uniform数组，4个元素，数量由你的着色器程序文件中uniform对象个数
    GLint uniform[NUM_UNIFORMS];
    
    GLuint id;
} programInfo_t;

//注意数据结构
/*
  programInfo_t 结构体，相当于数据类型
  program 数组名，相当于变量名
  NUM_PROGRAMS 1,数组元素个数

  "point.vsh"和"point.fsh";2个着色器程序文件名是作为program[0]变量中
  vert,frag2个字符指针的值。
  uniform 和 id 是置空的。
 
 */

programInfo_t program[NUM_PROGRAMS] = {
    { "point.vsh",   "point.fsh" },
};


//纹理
typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;

@implementation ZYPPoint

- (instancetype)initWithCGPoint:(CGPoint)point {
    self = [super init];
    
    if (self) {
        //类型转换
        self.mX = [NSNumber numberWithDouble:point.x];
        self.mY = [NSNumber numberWithDouble:point.y];
    }
    
    return self;
}


@end

@interface ZYPDrawingBoardView ()
{
    
}

@end

@implementation ZYPDrawingBoardView



@end
