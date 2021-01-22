//
//  ZYPSkyBoxViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/14.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPSkyBoxViewController.h"
#import "starship.h"
#import "ZYPSkyBoxEffect.h"

@interface ZYPSkyBoxViewController ()

@property (nonatomic,strong) EAGLContext *mContext;
//简单的照明和阴影渲染
@property (nonatomic,strong) GLKBaseEffect *baseEffect;
//天空盒子效果
@property (nonatomic,strong) ZYPSkyBoxEffect *skyboxEffect;
//眼睛的位置
@property (nonatomic,assign,readwrite) GLKVector3 eyePosition;
//观察者的位置
@property (nonatomic,assign) GLKVector3 lookAtPosition;
//观察者向上的方向的世界坐标系 的方向
@property (nonatomic,assign) GLKVector3 upVector;
//旋转角度
@property (nonatomic,assign) float angle;
//顶点
@property (nonatomic,assign) GLuint positionBuffer;
//法线
@property (nonatomic,assign) GLuint normalBuffer;

@property (weak, nonatomic) IBOutlet UISwitch *pauseSwitch;

@end

@implementation ZYPSkyBoxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupRC];
}

- (void)setupRC{
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView*)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.mContext];
    
    self.eyePosition = GLKVector3Make(0, 10.0f, 10.0f);
    self.lookAtPosition = GLKVector3Make(0, 0, 0);
    self.upVector = GLKVector3Make(0, 1.0f, 0);
    
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.position = GLKVector4Make(0, 0, 2.0f, 1.0f);
    //反射光的颜色
    self.baseEffect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
    //漫反射光的颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);
    //计算光照的策略
    //GLKLightingTypePerVertex:表示在三角形的每个顶点执行照明计算，然后在三角形中插值。
    //GLKLightingTypePerPixel指示对照明计算的输入在三角形内进行插值，并在每个片段上执行照明计算。
    self.baseEffect.lightingType = GLKLightingTypePerPixel;
    
    self.angle = 0.5;
    
    [self setMatrices];
    
    
    glGenVertexArraysOES(1, &_positionBuffer);
    glBindVertexArrayOES(_positionBuffer);
    
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(starshipPositions), starshipPositions, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(starshipNormals), starshipNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"skybox3" ofType:@"png"];
    NSError *error = nil;
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader cubeMapWithContentsOfFile:path options:nil error:&error];
    if (error) {
        NSLog(@"TextureInfo load error %@",error);
    }
    
    self.skyboxEffect = [[ZYPSkyBoxEffect alloc]init];
    self.skyboxEffect.textureCubeMap.name = textureInfo.name;
    self.skyboxEffect.textureCubeMap.target = textureInfo.target;
    
    self.skyboxEffect.xSize = 6.0f;
    self.skyboxEffect.ySize = 6.0f;
    self.skyboxEffect.zSize = 6.0f;
    
}

- (void)setMatrices{
    const GLfloat aspectRatio = (GLfloat)(self.view.bounds.size.width)/(GLfloat)(self.view.bounds.size.height);
    
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f), aspectRatio, 0.1f, 20.0f);
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(
                                                                     self.eyePosition.x, self.eyePosition.y, self.eyePosition.z, self.lookAtPosition.x, self.lookAtPosition.y, self.lookAtPosition.z, self.upVector.x, self.upVector.y, self.upVector.z);
    self.angle += 0.01;
    
    self.eyePosition = GLKVector3Make(-5.0f * sinf(self.angle), -5.0f, -5.0f*cos(self.angle));
    
    self.lookAtPosition = GLKVector3Make(0.0, 1.5 + -5.0f*sinf(0.3*self.angle), 0.0);
    
}
- (void)update{
//    NSTimeInterval timeElapsed = self.timeSinceFirstResume;
    //上一次更新时间
    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    //上一次绘制的时间
    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    //第一次恢复时间
    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    //上一次恢复时间
    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
    
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.5f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (!self.pauseSwitch.on) {
        [self setMatrices];
    }
    
    //更新天空盒的眼睛\投影矩阵\模型视图矩阵
    self.skyboxEffect.center = self.eyePosition;
    self.skyboxEffect.transform.projectionMatrix = self.baseEffect.transform.projectionMatrix;
    self.skyboxEffect.transform.modelviewMatrix = self.baseEffect.transform.modelviewMatrix;
    
    [self.skyboxEffect prepareToDraw];
    
    /*
     1. 深度缓冲区
     
     深度缓冲区原理就是把一个距离观察平面(近裁剪面)的深度值(或距离)与窗口中的每个像素相关联。
     
     
     1> 首先使用glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH)来打开DEPTH_BUFFER
     void glutInitDisplayMode(unsigned int mode);
     
     2>  每帧开始绘制时，须清空深度缓存 glClear(GL_DEPTH_BUFFER_BIT); 该函数把所有像素的深度值设置为最大值(一般是远裁剪面)
     
     3> 必要时调用glDepthMask(GL_FALSE)来禁止对深度缓冲区的写入。绘制完后在调用glDepthMask(GL_TRUE)打开DEPTH_BUFFER的读写（否则物体有可能显示不出来）
     
     注意：只要存在深度缓冲区，无论是否启用深度测试（GL_DEPTH_TEST），OpenGL在像素被绘制时都会尝试将深度数据写入到缓冲区内，除非调用了glDepthMask(GL_FALSE)来禁止写入。
     在绘制天空盒子的时候,禁止深度缓冲区
     */
    glDepthMask(false);
    [self.skyboxEffect draw];
    glDepthMask(true);
    
    //将缓存区、纹理清空
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    
    // 需要重新设置顶点数据，不需要缓存
    /*
     很多应用会在同一个渲染帧调用多次glBindBuffer()、glEnableVertexAttribArray()和glVertexAttribPointer()函数（用不同的顶点属性来渲染多个对象）
     新的顶点数据对象(VAO) 扩展会几率当前上下文中的与顶点属性相关的状态，并存储这些信息到一个小的缓存中。之后可以通过单次调用glBindVertexArrayOES() 函数来恢复，不需要在调用glBindBuffer()、glEnableVertexAttribArray()和glVertexAttribPointer()。
    */
    glBindVertexArrayOES(self.positionBuffer);
    
    for (int i= 0; i<starshipMaterials; i++) {
        
        //设置材质的漫反射颜色
        self.baseEffect.material.diffuseColor = GLKVector4Make(starshipDiffuses[i][0], starshipDiffuses[i][1], starshipDiffuses[i][2], 1.0f);
        
        //设置反射光颜色
        self.baseEffect.material.specularColor = GLKVector4Make(starshipSpeculars[i][0], starshipSpeculars[i][1], starshipSpeculars[i][2], 1.0f);
        
        //飞船准备绘制
        [self.baseEffect prepareToDraw];
        
        glDrawArrays(GL_TRIANGLES, starshipFirsts[i], starshipCounts[i]);
    }
}

@end
