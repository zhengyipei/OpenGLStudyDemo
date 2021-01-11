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
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    GLuint viewRenderBuffer,viewFrameBuffer;
    
    textureInfo_t brushTexture;
    GLfloat brushColor[4];
    
    Boolean firshTouch;
    Boolean needsErase;
    
    GLuint vertexShader;
    GLuint framentShader;
    GLuint shaderProgram;
    
    GLuint vboId;
    
    BOOL initialized;
    
    NSMutableArray *CCArr;
}

@end

@implementation ZYPDrawingBoardView

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyRetainedBacking, nil];
        context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }
        self.contentScaleFactor = [[UIScreen mainScreen]scale];
        needsErase = YES;
    }
    return self;
}

- (void)layoutSubviews{
    [EAGLContext setCurrentContext:context];
    
    if (!initialized) {
        initialized = [self initGL];
    }
    else{
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
    if (needsErase) {
        [self erase];
        needsErase = NO;
    }
}

- (BOOL)initGL{
    
    glGenFramebuffers(1, &viewFrameBuffer);
    glGenRenderbuffers(1, &viewRenderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"");
        return  NO;
    }
    
    glViewport(0, 0, backingWidth, backingHeight);
    glGenBuffers(1, &vboId);
    
    brushTexture = [self textureFromName:@"Particle.png"];
    
    [self setupShaders];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"abc" ofType:@"string"];
    NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    CCArr = [NSMutableArray array];
    
    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    for (NSDictionary *dic in jsonArr) {
        ZYPPoint *point = [ZYPPoint new];
        point.mX = [dic objectForKey:@"mX"];
        point.mY = [dic objectForKey:@"mY"];
        [CCArr addObject:point];
    }
    
    [self performSelector:@selector(paint) withObject:nil afterDelay:0.5];
    
    return  YES;
}
- (void)paint{
    for (int i = 0; i < CCArr.count - 1; i+=2) {
        ZYPPoint *cp1 = CCArr[i];
        ZYPPoint *cp2 = CCArr[i+1];
        CGPoint p1,p2;
        p1.x = cp1.mX.floatValue;
        p2.x = cp2.mX.floatValue;
        
        p1.y = cp1.mY.floatValue;
        p2.y = cp2.mY.floatValue;
        
        [self renderLineFromPoint:p1 toPoint:p2];
    }
}
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end{
    static GLfloat *vertexBuffer = NULL;
    static NSInteger vertexMax = 64;
    NSUInteger vertexCount = 0,count;
    
    CGFloat scale = self.contentScaleFactor;
    start.x *= scale;
    start.y *= scale;
    end.x *= scale;
    end.y *= scale;
    
    if (vertexBuffer == NULL) {
        vertexBuffer = malloc(vertexMax * 2 *sizeof(GLfloat));
    }
    
    float seq = sqrtf((end.x - start.x)*(end.x - start.x) + (end.y - start.y)*(end.y-start.y));
    
    NSInteger pointCont = ceilf(seq / kBrushPixelStep);
    count = MAX(pointCont, 1);
    for (int i = 0; i<count; i++) {
        if (vertexCount == vertexMax) {
            vertexMax *= 2;
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
        }
        vertexBuffer[2*vertexCount + 0] = start.x + (end.x - start.x)*((CGFloat)i/(CGFloat)count);
        vertexBuffer[2*vertexCount + 1] = start.y + (end.y - start.y)*((CGFloat)i/(CGFloat)count);
        vertexCount += 1;
    }
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    glBufferData(GL_ARRAY_BUFFER, vertexCount * 2 *sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
    
    glUseProgram(program[PROGRAM_POINT].id);
    glDrawArrays(GL_POINTS, 0, (int)vertexCount);
    
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupShaders{
    for (int i = 0; i<NUM_PROGRAMS; i++) {
        char *vsrc = readFile(pathForResource(program[i].vert));
        char *fsrc = readFile(pathForResource(program[i].frag));
        
        GLsizei attribCt = 0;
        GLchar *attribUsed[NUM_ATTRIBS];
        GLint attrib[NUM_ATTRIBS];
        GLchar *attribName[NUM_ATTRIBS] = {
            "inVertex",
        };
        const GLchar *uniformName[NUM_UNIFORMS] = {
            "MVP","pointSize","vertexColor","texture",
        };
        for (int j = 0; j<NUM_ATTRIBS; j++) {
            if (strstr(vsrc, attribName[j])) {
                attrib[attribCt] = j;
                attribUsed[attribCt++] = attribName[j];
            }
        }
        glueCreateProgram(vsrc, fsrc, attribCt, (const GLchar **)&attribUsed[0], attrib, NUM_UNIFORMS, &uniformName[0], program[i].uniform, &program[i].id);
        free(vsrc);
        free(fsrc);
        
        if (i == PROGRAM_POINT) {
            glUseProgram(program[PROGRAM_POINT].id);
            glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
        }
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
        
        GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
        GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
        glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
        glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width/kBrushScale);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
        
    }
    glError();
}

- (textureInfo_t)textureFromName:(NSString*)name{
    CGImageRef brushImage;
    CGContextRef brushContext;
    GLubyte *brushData;
    size_t width,height;
    GLuint texId;
    textureInfo_t texture;
    
    brushImage = [UIImage imageNamed:name].CGImage;
    
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    
    brushData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    
    
    brushContext = CGBitmapContextCreate(brushData, width, height, 8, width *4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(brushContext, CGRectMake(0, 0, width, height), brushImage);
    
    CGContextRelease(brushContext);
    
    glGenTextures(1, &texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
    free(brushData);
    
    texture.id = texId;
    texture.width = (int)width;
    texture.height = (int)height;
    
    return texture;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer{
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    if (glCheckFramebufferStatus(GL_RENDERBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Make compelete framebuffer object failed!%x",glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    glViewport(0, 0, backingWidth, backingHeight);
    
    return YES;
}
- (void)erase{
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glClearColor(0, 0, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)dealloc{
    if (viewFrameBuffer) {
        glDeleteBuffers(1, &viewFrameBuffer);
        viewFrameBuffer = 0;
    }
    if (viewRenderBuffer) {
        glDeleteBuffers(1, &viewRenderBuffer);
        viewRenderBuffer = 0;
    }
    if (brushTexture.id) {
        glDeleteTextures(1, &brushTexture.id);
        brushTexture.id = 0;
    }
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
}
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue{
    brushColor[0] = red * kBrushOpacity;
    brushColor[1] = green * kBrushOpacity;
    brushColor[2] = blue * kBrushOpacity;
    brushColor[3] = kBrushOpacity;
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

#pragma mark - *** touch click
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGRect bounds = [self bounds];
    UITouch * touch = [[event touchesForView:self]anyObject];
    firshTouch = YES;
    
    _location = [touch locationInView:self];
    _location.y = bounds.size.height - _location.y;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGRect bounds = [self bounds];
    UITouch *touch = [[event touchesForView:self]anyObject];
    if (firshTouch) {
        firshTouch = NO;
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
    }else{
        _location = [touch locationInView:self];
        _location.y = bounds.size.height - _location.y;
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
    }
    [self renderLineFromPoint:_previousLocation toPoint:_location];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGRect bounds = [self bounds];
    UITouch *touch = [[event touchesForView:self]anyObject];
    
    if (firshTouch) {
        firshTouch = NO;
        _previousLocation = [touch previousLocationInView:self];
        _previousLocation.y = bounds.size.height - _previousLocation.y;
        [self renderLineFromPoint:_previousLocation toPoint:_location];
    }
}


-(BOOL)canBecomeFirstResponder{
    return YES;
}


@end
