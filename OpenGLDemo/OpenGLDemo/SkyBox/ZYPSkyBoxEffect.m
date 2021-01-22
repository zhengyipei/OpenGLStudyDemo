//
//  ZYPSkyBoxEffect.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/14.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPSkyBoxEffect.h"

//立方体顶点索引数2*6 绘制立方体的三角形索引
const static int SkyboxNumVertexIndices = 14;

const static int SkyboxNumCoords = 24;

enum
{
    MVPMatrix,
    SamplersCube,
    NumUniforms,
};

@interface ZYPSkyBoxEffect()
{
    GLuint vertexBufferID;
    GLuint indexBufferID;
    GLuint program;
    GLuint vertexArrayID;
    GLint uniforms[NumUniforms];
}



@end

@implementation ZYPSkyBoxEffect

- (instancetype)init{
    if (self = [super init]) {
        _textureCubeMap = [[GLKEffectPropertyTexture alloc]init];
        _textureCubeMap.enabled = YES;
        _textureCubeMap.name = 0;
        _textureCubeMap.target = GLKTextureTargetCubeMap;
        //纹理用于计算其输出片段颜色的模式,看GLKTextureEnvMode
        /*
         GLKTextureEnvModeReplace, 输出颜色由从纹理获取的颜色.忽略输入的颜色
         GLKTextureEnvModeModulate, 输出颜色是通过将纹理颜色与输入颜色来计算所得
         GLKTextureEnvModeDecal,输出颜色是通过使用纹理的alpha组件来混合纹理颜色和输入颜色来计算的。
         */
        _textureCubeMap.envMode = GLKTextureEnvModeReplace;
        
        _transform = [[GLKEffectPropertyTransform alloc]init];
        self.center = GLKVector3Make(0, 0, 0);
        self.xSize = 1.0f;
        self.ySize = 1.0f;
        self.zSize = 1.0f;
        
        const float vertices[SkyboxNumCoords] = {
            -0.5, -0.5,  0.5,
            0.5, -0.5,  0.5,
            -0.5,  0.5,  0.5,
            0.5,  0.5,  0.5,
            -0.5, -0.5, -0.5,
            0.5, -0.5, -0.5,
            -0.5,  0.5, -0.5,
            0.5,  0.5, -0.5,
        };
        glGenBuffers(1, &vertexBufferID);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
       
        //绘制立方体的三角形带索引
        const GLubyte indices[SkyboxNumVertexIndices] = {
            1,2,3,7,1,5,4,7,6,2,4,0,1,2
        };
        glGenBuffers(1, &indexBufferID);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
        
    }
    return self;
}

- (void)prepareToDraw {
    if (program == 0) {
        [self loadShaders];
    }
    if (program != 0) {
        glUseProgram(program);
        
        GLKMatrix4 skyboxModelView = GLKMatrix4Translate(self.transform.modelviewMatrix, self.center.x, self.center.y, self.center.z);
        skyboxModelView = GLKMatrix4Scale(skyboxModelView, self.xSize, self.ySize, self.zSize);
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, skyboxModelView);
        glUniformMatrix4fv(uniforms[MVPMatrix], 1, GL_FALSE, modelViewProjectionMatrix.m);
        
        glUniform1i(uniforms[SamplersCube], 0);
        
        if (vertexArrayID == 0) {
            glGenVertexArraysOES(1, &vertexArrayID);
            glBindVertexArrayOES(vertexArrayID);
            
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
            
            glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        }else{
            glBindVertexArrayOES(vertexArrayID);
        }
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
        if (self.textureCubeMap.enabled) {
            glBindTexture(GL_TEXTURE_CUBE_MAP, self.textureCubeMap.name);
//            glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//            glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//            glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//            glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
////            glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        }else{
            glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
        }
    }
}
- (void)draw{
    /*
     索引绘制方法
     glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
     参数列表:
     mode:指定绘制图元的类型,但是如果GL_VERTEX_ARRAY 没有被激活的话，不能生成任何图元。它应该是下列值之一: GL_POINTS, GL_LINE_STRIP,GL_LINE_LOOP,GL_LINES,GL_TRIANGLE_STRIP,GL_TRIANGLE_FAN,GL_TRIANGLES,GL_QUAD_STRIP,GL_QUADS,GL_POLYGON
     count:绘制图元的数量
     type 为索引数组(indices)中元素的类型，只能是下列值之一:GL_UNSIGNED_BYTE,GL_UNSIGNED_SHORT,GL_UNSIGNED_INT
    indices：指向索引数组的指针。
     */
    glDrawElements(GL_TRIANGLE_STRIP, SkyboxNumVertexIndices, GL_UNSIGNED_BYTE, NULL);
}

- (void)dealloc{
    if (vertexArrayID != 0) {
        glDeleteVertexArraysOES(1, &vertexArrayID);
        vertexArrayID = 0;
    }
    if (vertexBufferID != 0) {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glDeleteBuffers(1, &vertexBufferID);
    }
    if (indexBufferID != 0) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glDeleteBuffers(1, &indexBufferID);
    }
    if (program != 0) {
        glUseProgram(0);
        glDeleteProgram(program);
    }
}
#pragma mark -  OpenGL ES shader compilation
- (BOOL)loadShaders{
    
    GLuint vertShader,fragShader;
    NSString *vertShaderPathName, *fragShaderPathName;
    
    program = glCreateProgram();
    
    vertShaderPathName = [[NSBundle mainBundle]pathForResource:@"SkyBoxShader" ofType:@"vsh"];
    
    if (![self complieShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathName]) {
        NSLog(@"Failed to complie vertex shader");
        return NO;
    }
    
    fragShaderPathName = [[NSBundle mainBundle]pathForResource:@"SkyBoxShader" ofType:@"fsh"];
 
    if (![self complieShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathName]) {
        NSLog(@"Failed to complie fragment shader");
        return NO;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glBindAttribLocation(program, GLKVertexAttribPosition, "a_position");
    
    if (!([self linkProgram:program])) {
        NSLog(@"Failed to load program: %d",program);
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return NO;
    }
    
    uniforms[MVPMatrix] = glGetUniformLocation(program, "u_mvpMatrix");
    uniforms[SamplersCube] = glGetUniformLocation(program, "u_samplersCube");
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)complieShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file{
    
    const GLchar *source;
    source = (GLchar*)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]UTF8String];
    
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength>0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"shader complie log:\n%s",log);
        free(log);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog{
    glLinkProgram(prog);
    
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar*log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s",log);
        return NO;
    }
    return YES;
}

@end
