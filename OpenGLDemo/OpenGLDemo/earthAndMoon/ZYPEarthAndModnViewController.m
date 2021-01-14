//
//  ZYPEarthAndModnViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/12.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPEarthAndModnViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sphere.h"

//地球轴倾斜度
static const GLfloat SceneEarthAxialTiltDeg = 23.5f;
//月球轨道日数
static const GLfloat SceneDaysPerMoonOrbit = 28.0f;
//半径
static const GLfloat SceneMoonRadiusFractionOfEarth = 0.25;
//月球距离地球的距离
static const GLfloat SceneMoonDistanceFromEarth = 1.0f;

@interface ZYPEarthAndModnViewController ()

@property (nonatomic,strong) EAGLContext *mContext;

@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexPositionBuffer;

@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexNormalBuffer;

@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexTexturCoorBuffer;

@property (nonatomic,strong) GLKBaseEffect *baseEffect;

@property (nonatomic,strong) GLKTextureInfo *earthTextureInfo;

@property (nonatomic,strong) GLKTextureInfo *moonTextureInfo;

@property (nonatomic,assign) GLKMatrixStackRef modelViewMatrixStack;

@property (nonatomic,assign) GLfloat earthRotationAngleDegress;

@property (nonatomic,assign) GLfloat moonRotationAngleDegress;

@end

@implementation ZYPEarthAndModnViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"地球与月亮";
    
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView*)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    glEnable(GL_DEPTH_TEST);
    
    self.baseEffect = [[GLKBaseEffect alloc]init];
    
    [self configureLight];
    
    GLfloat aspectRatio = self.view.bounds.size.width / self.view.bounds.size.height;
    
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0*aspectRatio, 1.0*aspectRatio, -1.0, 1.0, 2.0, 120.0f);
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
    GLKVector4 colorVector4 = GLKVector4Make(0, 0, 0, 1.0f);
    [self setClearColor:colorVector4];
    
    [self bufferData];
}
- (void)bufferData{
    self.modelViewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    //顶点数据缓存
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:3*sizeof(GLfloat) numberOfVertices:sizeof(sphereVerts)/(3*sizeof(GLfloat)) bytes:sphereVerts usage:GL_STATIC_DRAW];
    //光照,法线坐标
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:3*sizeof(GLfloat) numberOfVertices:sizeof(sphereNormals)/(3*sizeof(GLfloat)) bytes:sphereNormals usage:GL_STATIC_DRAW];
    //纹理坐标
    self.vertexTexturCoorBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(GLfloat)*2 numberOfVertices:sizeof(sphereTexCoords)/(2*sizeof(GLfloat)) bytes:sphereTexCoords usage:GL_STATIC_DRAW];
    
    //地球纹理
    CGImageRef earthImageRef = [UIImage imageNamed:@"Earth512x256.jpg"].CGImage;
    NSDictionary *earthOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    self.earthTextureInfo = [GLKTextureLoader textureWithCGImage:earthImageRef options:earthOptions error:NULL];
    
    //月亮纹理
    CGImageRef moonImageRef = [UIImage imageNamed:@"Moon256x128"].CGImage;
    NSDictionary *moonOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    self.moonTextureInfo = [GLKTextureLoader textureWithCGImage:moonImageRef options:moonOptions error:NULL];
    
    GLKMatrixStackLoadMatrix4(self.modelViewMatrixStack, self.baseEffect.transform.modelviewMatrix);
    self.moonRotationAngleDegress = -20.0f;
    
}
- (void)setClearColor:(GLKVector4)clearColorRGBA{
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}
- (void)configureLight{
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 0, 0, 0);
    self.baseEffect.light0.ambientColor = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
}

#pragma mark - *** drawRect
- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect{
    
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    _earthRotationAngleDegress += 360.0f/60.0f;
    _moonRotationAngleDegress += (360.0f/60.0f)/SceneDaysPerMoonOrbit;
    
    [self.vertexPositionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertexNormalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertexTexturCoorBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
    
    [self drawEarth];
    [self drawMoon];
    
}

- (void)drawEarth{
    self.baseEffect.texture2d0.name = self.earthTextureInfo.name;
    self.baseEffect.texture2d0.target = self.earthTextureInfo.target;
    
    GLKMatrixStackPush(self.modelViewMatrixStack);
    
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(SceneEarthAxialTiltDeg), 1.0f, 0.0f, 0.0f);
    
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(_earthRotationAngleDegress), 0.0f, 1.0f, 0.0f);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    GLKMatrixStackPop(self.modelViewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
}
- (void)drawMoon{
    self.baseEffect.texture2d0.name = self.moonTextureInfo.name;
    self.baseEffect.texture2d0.target = self.moonTextureInfo.target;
    
    GLKMatrixStackPush(self.modelViewMatrixStack);
    
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(_moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);
    
    GLKMatrixStackTranslate(self.modelViewMatrixStack, 0.0f, 0.0f, SceneMoonDistanceFromEarth);
    
    GLKMatrixStackScale(self.modelViewMatrixStack, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    GLKMatrixStackPop(self.modelViewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            toInterfaceOrientation !=
            UIInterfaceOrientationPortrait);
}
- (IBAction)rightBtnAction:(UISegmentedControl *)sender {
    GLfloat aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    if (sender.selectedSegmentIndex == 0) {
        self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(-1.0*aspect, 1.0*aspect, -1.0, 1.0, 2.0, 120);
    }else{
        self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0*aspect, 1.0*aspect, -1.0, 1.0, 2.0, 120.0);
    }
}
@end
