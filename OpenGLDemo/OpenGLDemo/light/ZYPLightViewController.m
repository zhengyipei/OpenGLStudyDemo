//
//  ZYPLightViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/13.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPLightViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sceneUtil.h"

@interface ZYPLightViewController ()

@property (nonatomic,strong) EAGLContext *mContext;
//基本光照纹理
@property (nonatomic,strong) GLKBaseEffect *baseEffect;
//额外光照纹理
@property (nonatomic,strong) GLKBaseEffect *extraEffect;
//顶点缓存区
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexBuffer;
//法线位置缓冲区
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *extraBuffer;
//是否使用面法线
@property (nonatomic,assign) BOOL shouldUseFaceNormals;
//是否绘制法线
@property (nonatomic,assign) BOOL shouldDrawNormals;
//中心高点
@property (nonatomic,assign) GLfloat centerVertexHeight;
@end

@implementation ZYPLightViewController
{
    SceneTriangle triangles[NUM_FACES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.5f, 0.5f, 0.5f, 1.0f);
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 1.0f, 0.0f);
    
    self.extraEffect = [[GLKBaseEffect alloc]init];
    self.extraEffect.useConstantColor = GL_TRUE;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-60.0f), 1.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(-30.0f), 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, 0.25f);
    
    self.baseEffect.transform.modelviewMatrix = modelViewMatrix;
    self.extraEffect.transform.modelviewMatrix = modelViewMatrix;
    
    
    [self setClearColor:GLKVector4Make(0, 0, 0, 1.0f)];
    
    triangles[0] = SceneTriangleMake(vertexA, vertexD, vertexB);
    triangles[1] = SceneTriangleMake(vertexB, vertexC, vertexF);
    triangles[2] = SceneTriangleMake(vertexB, vertexE, vertexD);
    triangles[3] = SceneTriangleMake(vertexB, vertexF, vertexE);
    triangles[4] = SceneTriangleMake(vertexE, vertexH, vertexD);
    triangles[5] = SceneTriangleMake(vertexE, vertexF, vertexH);
    triangles[6] = SceneTriangleMake(vertexD, vertexH, vertexG);
    triangles[7] = SceneTriangleMake(vertexF, vertexH, vertexI);
    
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(SceneVertex) numberOfVertices:(sizeof(triangles)/sizeof(SceneTriangle))*(sizeof(SceneTriangle)/sizeof(SceneVertex)) bytes:triangles usage:GL_DYNAMIC_DRAW];
    
    self.extraBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(SceneVertex) numberOfVertices:0 bytes:NULL usage:GL_DYNAMIC_DRAW];
    
    self.centerVertexHeight = 0.0f;
    
    self.shouldUseFaceNormals = YES;
    
}

- (void)setClearColor:(GLKVector4)clearColorRGBA{
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(SceneVertex, position) shouldEnable:YES];
    
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:offsetof(SceneVertex, normal) shouldEnable:YES];
    
    [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sizeof(triangles)/sizeof(SceneVertex)];
    
    if (self.shouldDrawNormals) {
        [self drawNormals];
    }
}

//绘制法线
-(void)drawNormals
{
    GLKVector3 normalLineVertices[NUM_LINE_VERTS];
    
    SceneTrianglesNormalLinesUpdate(triangles, GLKVector3MakeWithArray(self.baseEffect.light0.position.v), normalLineVertices);
    
    [self.extraBuffer reinitWithAttribStride:sizeof(GLKVector3) numberOfVertices:NUM_LINE_VERTS bytes:normalLineVertices];
    
    [self.extraBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    
    self.extraEffect.useConstantColor = GL_TRUE;
    self.extraEffect.constantColor = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    
    [self.extraEffect prepareToDraw];
    
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:0 numberOfVertices: NUM_NORMAL_LINE_VERTS];
    
    self.extraEffect.constantColor = GLKVector4Make(1.0, 1.0, 0, 1.0);
    
    [self.extraEffect prepareToDraw];
    
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:NUM_NORMAL_LINE_VERTS numberOfVertices:(NUM_LINE_VERTS-NUM_NORMAL_LINE_VERTS)];
    
    
    
}
//更新法向量
-(void)updateNormals
{
    if (self.shouldUseFaceNormals) {
        //更新每个点的平面法向量
        SceneTrianglesUpdateFaceNormals(triangles);
    }else
    {
        //通过平均值求出每个点的法向量
        SceneTrianglesUpdateVertexNormals(triangles);
    }
    [self.vertexBuffer reinitWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles];
    
    
}

#pragma mark --Set
-(void)setCenterVertexHeight:(GLfloat)centerVertexHeight
{
    _centerVertexHeight = centerVertexHeight;
    
    //更新顶点 E
    SceneVertex newVertexE = vertexE;
    newVertexE.position.z = centerVertexHeight;
    
    triangles[2] = SceneTriangleMake(vertexD, vertexB, newVertexE);
    triangles[3] = SceneTriangleMake(newVertexE, vertexB, vertexF);
    triangles[4] = SceneTriangleMake(vertexD, newVertexE, vertexH);
    triangles[5] = SceneTriangleMake(newVertexE, vertexF, vertexH);
    
    //更新法线
    [self updateNormals];
    
}

-(void)setShouldUseFaceNormals:(BOOL)shouldUseFaceNormals
{
    if (shouldUseFaceNormals != _shouldUseFaceNormals) {
        
        _shouldUseFaceNormals = shouldUseFaceNormals;
        
        [self updateNormals];
    }
}

#pragma makr --UI Change
//绘制屏幕法线
- (IBAction)takeShouldUseFaceNormals:(UISwitch *)sender {
    
    
     self.shouldUseFaceNormals = sender.isOn;
   
}

//绘制法线
- (IBAction)takeShouldDrawNormals:(UISwitch *)sender {
    
     self.shouldDrawNormals = sender.isOn;
}

- (IBAction)changeCenterVertexHeight:(UISlider *)sender {
  
    self.centerVertexHeight = sender.value;
}
@end
