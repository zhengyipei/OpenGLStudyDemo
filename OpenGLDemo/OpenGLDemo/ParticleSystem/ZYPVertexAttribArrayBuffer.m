//
//  ZYPVertexAttribArrayBuffer.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/18.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPVertexAttribArrayBuffer.h"


@implementation ZYPVertexAttribArrayBuffer

- (id)initWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage{
    if (self = [super init]) {
        _stride = stride;
        _bufferSizeBytes = stride * count;
        
        glGenBuffers(1, &_name);
        glBindBuffer(GL_ARRAY_BUFFER, _name);
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
        
    }
    return self;
}

- (void)reinitWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr{
    _stride = stride;
    _bufferSizeBytes = stride * count;
    
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
    
}

- (void)prepareToDrawWithAttrib:(GLuint)index numberOfCoordinates:(GLint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable{
    if (count < 0 || count >4) {
        NSLog(@"Error:Count Error");
        return;
    }
    if (_stride < offset) {
        NSLog(@"Error:_stride < Offset");
        return;
    }
    if (_name == 0) {
        NSLog(@"Error:name == null");
        return;;
    }
    glBindBuffer(GL_ARRAY_BUFFER, _name);
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, (int)self.stride, NULL+offset);
}

+ (void)drawPreparedArraysWithMode:(GLenum)mode startVertexIndex:(GLuint)first numberOfVertices:(GLsizei)count{
    glDrawArrays(mode, first, count);
}
- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count{
    if (self.bufferSizeBytes < (first+count)*self.stride) {
        NSLog(@"Vertex error");
    }
    glDrawArrays(mode, first, count);
}
- (void)dealloc{
    if (_name != 0) {
        glDeleteBuffers(1, &_name);
        _name = 0;
    }
}

@end
