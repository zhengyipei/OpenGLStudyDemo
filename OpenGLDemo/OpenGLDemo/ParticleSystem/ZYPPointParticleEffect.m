//
//  ZYPPointParticleEffect.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/18.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPPointParticleEffect.h"
#import "ZYPVertexAttribArrayBuffer.h"

typedef struct
{
    GLKVector3 emissionPosition;//发射位置
    GLKVector3 emissionVelocity;//发射速度
    GLKVector3 emissionForce;//发射重力
    GLKVector2 size;//发射大小
    GLKVector2 emissionTimeAndLife;//发射时间和寿命
}ParticleAttributes;

//GLSL程序Uniform参数
enum
{
    MVPMatrix,//MVP矩阵
    Samplers2D,//Samplers2D纹理
    ElapsedSeconds,//耗时
    Gravity,//重力
    NumUniforms//uniform 个数
};
//属性标识符
typedef enum {
    ParticleEmissionPosition = 0,
    ParticleEmissionVelocity,
    ParticleEmissionForce,
    ParticleSize,
    ParticleEmissionTimeAndLife,
}ParticleAttrib;

@interface ZYPPointParticleEffect()
{
    GLfloat elapsedSeconds;
    GLuint program;
    GLint uniforms[NumUniforms];
}

@property (nonatomic,strong) ZYPVertexAttribArrayBuffer *particleAttributeBuffer;

@property (nonatomic,assign) NSUInteger numberOfParticles;

@property (nonatomic,strong) NSMutableData *particleAttributesData;

@property (nonatomic,assign) BOOL particlelDataWasUpdated;

@end

@implementation ZYPPointParticleEffect

@synthesize texture2d0;
@synthesize transform;
@synthesize elapsedSeconds;

- (instancetype)init{
    if (self = [super init]) {
        texture2d0 = [[GLKEffectPropertyTexture alloc]init];
        texture2d0.enabled = YES;
        texture2d0.name = 0;
        texture2d0.target = GLKTextureTarget2D;
        texture2d0.envMode = GLKTextureEnvModeReplace;
        
        transform = [[GLKEffectPropertyTransform alloc]init];
        
        _gravity = mDefaultGravity;
        
        elapsedSeconds = 0.0f;
        
        _particleAttributesData = [NSMutableData data];
    }
    return self;
}
//获取粒子的属性值
- (ParticleAttributes)particleAtIndex:(NSInteger)index{
    const ParticleAttributes *particlePtr = (const ParticleAttributes*)[self.particleAttributesData bytes];
    return  particlePtr[index];
}

- (void)setParticle:(ParticleAttributes)aParticle atIndex:(NSInteger)index{
    ParticleAttributes *particlesPtr = (ParticleAttributes*)[self.particleAttributesData mutableBytes];
    
    particlesPtr[index ] = aParticle;
    self.particlelDataWasUpdated = YES;
}
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)size
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration{
    
    ParticleAttributes newParticle;
    newParticle.emissionPosition = aPosition;
    newParticle.emissionVelocity = aVelocity;
    newParticle.emissionForce = aForce;
    newParticle.size = GLKVector2Make(size, aDuration);
    newParticle.emissionTimeAndLife = GLKVector2Make(elapsedSeconds, elapsedSeconds+aSpan);
    
    BOOL foundSlot = NO;
    
    const long count = self.numberOfParticles;
    
    for (int i = 0; i<count; i++) {
        ParticleAttributes oldParticle = [self particleAtIndex:i];
        if (oldParticle.emissionTimeAndLife.y < self.elapsedSeconds) {
            [self setParticle:newParticle atIndex:i];
            foundSlot = YES;
        }
    }
    
    if (!foundSlot) {
        [self.particleAttributesData appendBytes:&newParticle length:sizeof(newParticle)];
        self.particlelDataWasUpdated = YES;
    }
    
}

- (NSUInteger)numberOfParticles{
    static long last;
    long ret = [self.particleAttributesData length] / sizeof(ParticleAttributes);
    
    if (last != ret) {
        last = ret;
    }
    return  ret;
}

- (void)prepareToDraw{
    if (program == 0) {
        [self loadShaders];
    }
    if (program != 0) {
        glUseProgram(program);
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix,self.transform.modelviewMatrix);
        glUniformMatrix4fv(uniforms[MVPMatrix], 1, 0, modelViewProjectionMatrix.m);
        
        glUniform1i(uniforms[Samplers2D], 0);
        
        glUniform3fv(uniforms[Gravity], 1, self.gravity.v);
        glUniform1fv(uniforms[ElapsedSeconds], 1, &elapsedSeconds);
        
        if (self.particlelDataWasUpdated) {
            GLsizeiptr size = sizeof(ParticleAttributes);
            int count = (int)[self.particleAttributesData length]/size;
            if (self.particleAttributeBuffer == nil && [self.particleAttributesData length] > 0) {
                self.particleAttributeBuffer = [[ZYPVertexAttribArrayBuffer alloc]initWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes] usage:GL_DYNAMIC_DRAW];
                
            }else{
                [self.particleAttributeBuffer reinitWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes]];
            }
            self.particlelDataWasUpdated = NO;
        }
        [self.particleAttributeBuffer prepareToDrawWithAttrib:ParticleEmissionPosition numberOfCoordinates:3 attribOffset:offsetof(ParticleAttributes, emissionPosition) shouldEnable:YES];
        [self.particleAttributeBuffer prepareToDrawWithAttrib:ParticleEmissionVelocity numberOfCoordinates:3 attribOffset:offsetof(ParticleAttributes, emissionVelocity) shouldEnable:YES];
        [self.particleAttributeBuffer prepareToDrawWithAttrib:ParticleEmissionForce numberOfCoordinates:3 attribOffset:offsetof(ParticleAttributes, emissionForce) shouldEnable:YES];
        [self.particleAttributeBuffer prepareToDrawWithAttrib:ParticleSize numberOfCoordinates:2 attribOffset:offsetof(ParticleAttributes, size) shouldEnable:YES];
        [self.particleAttributeBuffer prepareToDrawWithAttrib:ParticleEmissionTimeAndLife numberOfCoordinates:2 attribOffset:offsetof(ParticleAttributes, emissionTimeAndLife) shouldEnable:YES];
        
        glActiveTexture(GL_TEXTURE0);
        if (self.texture2d0.name != 0 && self.texture2d0.enabled) {
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }else{
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}
- (void)draw{
    glDepthMask(GL_FALSE);
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    glDepthMask(GL_TRUE);
}

//加载shaders
- (BOOL)loadShaders{
    
    GLuint vertShader, fragShader;
    NSString *vertShaderPathName ,*fragShaderPahtName;
    
    program = glCreateProgram();
    
    vertShaderPathName = [[NSBundle mainBundle]pathForResource:@"PointParticlesShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathName]) {
        NSLog(@"Failed to comple vertex shader");
        return NO;
    }
    fragShaderPahtName = [[NSBundle mainBundle]pathForResource:@"PointParticlesShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPahtName]) {
        NSLog(@"Failed to comple fragment shader");
        return NO;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glBindAttribLocation(program, ParticleEmissionPosition, "a_emissionPosition");
    glBindAttribLocation(program, ParticleEmissionForce, "a_emissionForce");
    glBindAttribLocation(program, ParticleEmissionVelocity, "a_emissionVelocity");
    glBindAttribLocation(program, ParticleEmissionTimeAndLife, "a_emissionAndDeathTimes");
    glBindAttribLocation(program, ParticleSize, "a_size");
    
    if (![self linkProgram:program]) {
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
    uniforms[Samplers2D] = glGetUniformLocation(program, "u_samplers2D");
    uniforms[Gravity] = glGetUniformLocation(program, "u_gravity");
    uniforms[ElapsedSeconds] = glGetUniformLocation(program, "u_elapsedSeconds");
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteProgram(fragShader);
    }
    
    return YES;
}

//编译shaders
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file{
    const GLchar *source;
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    *shader  = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader comple log:\n%s",log);
        free(log);
        return  NO;
    }
    return  YES;
}
//链接Program
- (BOOL)linkProgram:(GLuint)prog{
    glLinkProgram(prog);
    GLint loglength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &loglength);
    if (loglength>0) {
        GLchar *log = (GLchar*)malloc(loglength);
        glGetProgramInfoLog(prog, loglength, &loglength, log);
        NSLog(@"Program link log:\n%s",log);
        free(log);
        return NO;
    }
    return YES;
}

//验证Program
- (BOOL)validateProgram:(GLuint)prog{
    glValidateProgram(prog);
    GLint logLenght,status;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLenght);
    if (logLenght > 0) {
        GLchar *log = (GLchar*)malloc(logLenght);
        glGetProgramInfoLog(prog, logLenght, &logLenght, log);
        NSLog(@"Program validate log:\n%s",log);
        free(log);
        return NO;
    }
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}
//默认重力加速度向量与地球的匹配
//{ 0，（-9.80665米/秒/秒），0 }假设+ Y坐标系的建立
//默认重力
const GLKVector3 mDefaultGravity = {0.0f, -9.80665f, 0.0f};

@end
