//
//  ZYPVertexAttribArrayBuffer.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/18.
//  Copyright © 2021 imac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef enum {
    ZYPVertexAttribPosition = GLKVertexAttribPosition,
    ZYPVertexAttribNormal = GLKVertexAttribNormal,
    ZYPVertexAttribColor = GLKVertexAttribColor,
    ZYPVertexAttribTextCoord0 = GLKVertexAttribTexCoord0,
    ZYPVertexAttribTextCoord1 = GLKVertexAttribTexCoord1,
} ZYPVertexAttrib;
NS_ASSUME_NONNULL_BEGIN

@interface ZYPVertexAttribArrayBuffer : NSObject

@property (nonatomic,readonly) GLuint name;
@property (nonatomic,readonly) GLsizeiptr bufferSizeBytes;
@property (nonatomic,readonly) GLsizeiptr stride;

//根据模式绘制已经准备数据
//绘制
/*
 mode:模式
 first:是否是第一次
 count:顶点个数
 */
+ (void)drawPreparedArraysWithMode:(GLenum)mode
                   startVertexIndex:(GLuint)first
                   numberOfVertices:(GLsizei)count;

//初始
/*
 stride:步长
 count:顶点个数
 dataPtr:数据指针
 usage:用法
 */
- (id)initWithAttribStride:(GLsizeiptr)stride
          numberOfVertices:(GLsizei)count
                     bytes:(const GLvoid *)dataPtr
                     usage:(GLenum)usage;

//初始
/*
 stride:步长
 count:顶点个数
 dataPtr:数据指针
 usage:用法
 */
- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable;

//绘制
/*
 mode:模式
 first:是否是第一次
 count:顶点个数
 */
- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count;

//接收数据`
/*
 stride:步长
 count:顶点个数
 dataPtr:数据指针
 */
- (void)reinitWithAttribStride:(GLsizeiptr)stride
              numberOfVertices:(GLsizei)count
                         bytes:(const GLvoid *)dataPtr;

@end

NS_ASSUME_NONNULL_END
