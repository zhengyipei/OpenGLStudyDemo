//
//  ZYPGLView.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/21.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPGLView.h"
@import OpenGLES;

typedef struct{
    float position[4];//顶点x,y,z,w
    float textureCoordinate[2];//纹理 s,t
}CustomerVertex;

//属性枚举
enum
{
    ATTRIBUTE_POSITION = 0,//属性顶点
    ATTRIBUTE_INPUT_TEXTURE_COORDINATE,//属性——输入纹理坐标
    TEMP_ATTRIBUTE_POSITION,//色温-属性-顶点位置
    TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE,//色温-属性-输入纹理坐标
    NUM_ATTRIBUTES,//属性个数
};

//属性数组
GLint glViewAttributes[NUM_ATTRIBUTES];

enum
{
    UNIFORM_INPUT_IMAGM_TEXTURE = 0,//输入纹理
    TEMP_UNIFORM_INPUT_IMAGE_TEXTURE,//色温-输入纹理
    UNIFORM_TEMPERATURE,//色温
    UNIFORM_SATURATION,//饱和度
    NUM_UNIFORMS//Uniforms个数
};

GLint glViewUniforms[NUM_UNIFORMS];

@interface ZYPGLView()
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint       _frameBuffer;
    GLuint       _renderBuffer;
    
    GLuint       _texture;
    
    GLuint       _tempFrameBuffer;
    GLuint       _tempTexture;
    GLuint       _tempRenderBuffer;
    
    GLuint       _programHandle;
    GLuint       _tempProgramHandle;
}

@end

@implementation ZYPGLView


- (void)setup{
    //设置色温饱和度
    [self setupData];
    //设置图层
    [self setupLayer];
    //设置上下文
    [self setupContext];
    //设置renderBuffer
    [self setupRenderBuffer];
    //
    [self setupFrameBuffer];
    //
    NSError *error;
    NSAssert1([self checkFrameBuffer:&error], @"%@", error.userInfo[@"ErrorMessage"]);
    //链接shader 色温
    [self compileTemperatureShaders];
    //链接shader 饱和度
    [self compileSaturationShaders];
    //设置VBO（Vertex Buffer Objects）
    [self setupVBOs];
    //设置纹理
    [self setupTemp];
}

- (void)setupData{
    _temperature = 0.5;
    _saturation = 0.5;
}
- (void)setupLayer{
    
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
}
- (void)setupContext{
    if (!_context) {
        _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
}
- (void)setupRenderBuffer{
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}
- (void)setupFrameBuffer{
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}
- (void)setupVBOs {
    static const CustomerVertex vertices[] =
    {
        {.position = {-1.0, -1.0, 0, 1}, .textureCoordinate = { 0.0, 0.0 } },
        {.position = {1.0, -1.0, 0, 1}, .textureCoordinate = { 1.0 , 0.0} },
        {.position = {-1.0,1.0,0,1}, .textureCoordinate = { 0.0, 1.0} },
        {.position = {1.0,1.0,0,1}, .textureCoordinate = {1.0, 1.0 } }
    };
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)setupTemp{
    glGenFramebuffers(1, &_tempFrameBuffer);
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_tempTexture);
    glBindTexture(GL_TEXTURE_2D, _tempTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _tempFrameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tempTexture, 0);
}

#pragma mark - *** Private
- (BOOL)checkFrameBuffer:(NSError *__autoreleasing *)error{
    
    GLenum stauts = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSString *errorMessage = nil;
    BOOL result = NO;
    switch (stauts) {
        case GL_FRAMEBUFFER_UNSUPPORTED:
            errorMessage = @"framebuffer不支持该格式";
            result = NO;
            break;
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"framebuffer 创建成功");
            result = YES;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            errorMessage = @"FrameBuffer 不完整 缺失组件";
            result = NO;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            errorMessage = @"FrameBuffer 不完整，附加图片必须指定大小";
            result = NO;
            break;
        default:
            errorMessage = @"未知错误 error ！";
            result = NO;
            break;
    }
    NSLog(@"%@",errorMessage ? errorMessage : @"");
    *error = errorMessage ? [NSError errorWithDomain:@"com.Yue.error" code:stauts userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
    
    return result;
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"shaderString 为空");
        exit(1);
    }
    GLuint shaderHandle = glCreateShader(shaderType);
    const char*shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FASTEST) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"compileShader glGetShaderiv shaderInfoLog: %@",messageString);
        exit(1);
    }
    return shaderHandle;
}

- (void)compileTemperatureShaders {
    GLuint vertexShader = [self compileShader:@"ImageVertexShader.vsh" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"ImageTemperature.fsh" withType:GL_FRAGMENT_SHADER];
    
    _programHandle = glCreateProgram();
    
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    
    glLinkProgram(_programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messagesString = [NSString stringWithUTF8String:messages];
        NSLog(@"compileTemperatureShaders glGetProgramiv ShaderInfoLog:%@",messagesString);
        exit(1);
    }
    glUseProgram(_programHandle);
    glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(_programHandle, "position");
    glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE] = glGetAttribLocation(_programHandle, "inputTextureCoordinate");
    
    glViewUniforms[UNIFORM_INPUT_IMAGM_TEXTURE] = glGetUniformLocation(_programHandle, "inputImageTexture");
    glViewUniforms[UNIFORM_TEMPERATURE] = glGetUniformLocation(_programHandle, "temperature");
    
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);
    
}
//饱和度
- (void)compileSaturationShaders {
    GLuint vertexShader = [self compileShader:@"ImageVertexShader.vsh" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"ImageSaturation.fsh" withType:GL_FRAGMENT_SHADER];
    
    _tempProgramHandle = glCreateProgram();
    
    glAttachShader(_tempProgramHandle, vertexShader);
    glAttachShader(_tempProgramHandle, fragmentShader);
    
    glLinkProgram(_tempProgramHandle);
    
    GLint linkSuccess;
    glGetProgramiv(_tempProgramHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_tempProgramHandle, sizeof(messages), 0, &messages[0]);
        NSString *messagesString = [NSString stringWithUTF8String:messages];
        NSLog(@"compileSaturationShaders glGetProgramiv ShaderInfoLog:%@",messagesString);
        exit(1);
    }
    glUseProgram(_tempProgramHandle);
    
    glViewAttributes[TEMP_ATTRIBUTE_POSITION] = glGetAttribLocation(_tempProgramHandle, "position");
    glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE] = glGetAttribLocation(_tempProgramHandle, "inputTextureCoordinate");
    
    glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_tempProgramHandle, "inputImageTexture");
    glViewUniforms[UNIFORM_SATURATION] = glGetUniformLocation(_tempProgramHandle, "saturation");
    
    glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);
}

- (void)render{
    //绘制第一个滤镜
    glUseProgram(_tempProgramHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _tempFrameBuffer);
    glViewport(0, 0, self.frame.size.width*self.contentScaleFactor, self.frame.size.height*self.contentScaleFactor);
    
    glClearColor(0, 0, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUniform1i(glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE], 1);
    glUniform1f(glViewUniforms[UNIFORM_SATURATION], _saturation);
    
    glVertexAttribPointer(glViewAttributes[TEMP_ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomerVertex), 0);
    glVertexAttribPointer(glViewAttributes[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomerVertex), (GLvoid *)(sizeof(float)*4));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //绘制第二个滤镜
    glUseProgram(_programHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);
    
    glUniform1i(glViewUniforms[UNIFORM_INPUT_IMAGM_TEXTURE], 0);
    glUniform1f(glViewUniforms[UNIFORM_TEMPERATURE], _temperature);
    
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomerVertex), 0);
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomerVertex), (GLvoid *)(sizeof(float)*4));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - *** Public
- (void)layoutGLViewWithImage:(UIImage *)image{
    [self setup];
    [self setupTextureWithImage:image];
    [self render];
}
- (void)setupTextureWithImage:(UIImage*)image{
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    //获取颜色组件
    CGColorSpaceRef colorSapce = CGColorSpaceCreateDeviceRGB();
    //3.计算图片数据大小->开辟空间
    void *imageData = malloc(height * width * 4);
    
    //创建位图context
    /*
     CGBitmapContextCreate(void * __nullable data,
     size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow,
     CGColorSpaceRef cg_nullable space, uint32_t bitmapInfo)
     参数列表:
     1.data,指向要渲染的绘制内存的地址
     2.width,bitmap的宽度,单位为像素
     3.height,bitmap的高度,单位为像素
     4.bitsPerComponent, 内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     5.bytesPerRow, bitmap的每一行在内存所占的比特数
     6.colorspace, bitmap上下文使用的颜色空间
     7.bitmapInfo,指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
     
     
     */
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, 4*width, colorSapce, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSapce);
    /*
     绘制透明矩形。如果所提供的上下文是窗口或位图上下文，则核心图形将清除矩形。对于其他上下文类型，核心图形以设备依赖的方式填充矩形。但是，不应在窗口或位图上下文以外的上下文中使用此函数
     CGContextClearRect(CGContextRef cg_nullable c, CGRect rect)
     参数:
     1.C,绘制矩形的图形上下文。
     2.rect,矩形，在用户空间坐标中。
     */
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    //CTM--从用户空间和设备空间存在一个转换矩阵CTM
    /*
     CGContextTranslateCTM(CGContextRef cg_nullable c,
     CGFloat tx, CGFloat ty)
     参数1:上下文
     参数2:X轴上移动距离
     参数3:Y轴上移动距离
     */
    CGContextTranslateCTM(context, 0, height);
    //缩小
    CGContextScaleCTM(context, 1, -1);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    
    CGContextRelease(context);
    //在绑定纹理之前,激活纹理单元 glActiveTexture
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //将图片载入纹理
    /*
     glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
     参数列表:
     1.target,目标纹理
     2.level,一般设置为0
     3.internalformat,纹理中颜色组件
     4.width,纹理图像的宽度
     5.height,纹理图像的高度
     6.border,边框的宽度
     7.format,像素数据的颜色格式
     8.type,像素数据数据类型
     9.pixels,内存中指向图像数据的指针
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,(GLint)width,(GLint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    
}
#pragma mark - *** setter
- (void)setTemperature:(CGFloat)temperature{
    _temperature = temperature;
    [self render];
}
- (void)setSaturation:(CGFloat)saturation{
    _saturation = saturation;
    [self render];
}
#pragma mark - *** life cycle
- (void)dealloc{
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    _context = nil;
}
+ (Class)layerClass{
    return [CAEAGLLayer class];
}


@end
