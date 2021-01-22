//
//  ZYPParticleSystemViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/18.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPParticleSystemViewController.h"
#import "ZYPVertexAttribArrayBuffer.h"
#import "ZYPPointParticleEffect.h"

@interface ZYPParticleSystemViewController ()

@property (nonatomic,strong) EAGLContext *mContext;

@property (nonatomic,strong) ZYPPointParticleEffect *particleEffect;

@property (nonatomic,assign) NSTimeInterval autoSpawnDelta;
@property (nonatomic,assign) NSTimeInterval lastSpawnTime;

@property (nonatomic,assign) NSInteger currentEmitterIndex;
@property (nonatomic,strong) NSArray *emitterBlocks;

@property (nonatomic,strong) GLKTextureInfo *ballParticleTexture;

@end

@implementation ZYPParticleSystemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView*)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.mContext];
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"ball" ofType:@"png"];
    if (path == nil) {
        NSLog(@"ball texture image not found");
    }
    
    NSError *error = nil;
    self.ballParticleTexture = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:&error];
    
    self.particleEffect = [[ZYPPointParticleEffect alloc]init];
    self.particleEffect.texture2d0.name = self.ballParticleTexture.name;
    self.particleEffect.texture2d0.target = self.ballParticleTexture.target;
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    void (^blockA)(void) = ^{
        self.autoSpawnDelta = 0.5f;
        self.particleEffect.gravity = mDefaultGravity;
        float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
        
        [self.particleEffect addParticleAtPosition:GLKVector3Make(0, 0, 0.9f) velocity:GLKVector3Make(randomXVelocity, 1.0f, -1.0f) force:GLKVector3Make(0, 9.0f, 0) size:8.0f lifeSpanSeconds:3.2f fadeDurationSeconds:0.5f];
    };
    void (^blockB)(void) = ^ {
        self.autoSpawnDelta = 0.05f;
        self.particleEffect.gravity = GLKVector3Make(0, 0.5, 0);
        int n = 50;
        for (int i = 0; i<n; i++) {
            float randomXVelocity = -0.1f + 0.2f * (float)random() / (float)RAND_MAX;
            float randomZVelocity = 0.1f + 0.2f * (float)random() / (float)RAND_MAX;
            
            [self.particleEffect addParticleAtPosition:GLKVector3Make(0, -0.5f, 0.0f) velocity:GLKVector3Make(randomXVelocity, 0.0, randomZVelocity) force:GLKVector3Make(0, 0, 0) size:16.f lifeSpanSeconds:2.2f fadeDurationSeconds:3.0f];
        }
    };
    
    void (^blockC)(void) = ^ {
        self.autoSpawnDelta = 0.5f;
        self.particleEffect.gravity = GLKVector3Make(0, 0, 0);
        int n = 100;
        for (int i = 0; i<n; i++) {
            //X,Y,Z速度
            float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomZVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            
            //创建粒子
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:GLKVector3Make(
                                     randomXVelocity,
                                     randomYVelocity,
                                     randomZVelocity)
             force:GLKVector3Make(0.0f, 0.0f, 0.0f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.5f];
        }
    };
    
    void(^blockD)(void) = ^{
        self.autoSpawnDelta = 3.2f;
        
        //重力
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        int n = 100;
        for(int i = 0; i < n; i++)
        {
            //X,Y速度
            float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            
            
            //GLKVector3Normalize 计算法向量
            //计算速度与方向
            GLKVector3 velocity = GLKVector3Normalize( GLKVector3Make(
                                                                     randomXVelocity,
                                                                     randomYVelocity,
                                                                     0.0f));
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:velocity
             force:GLKVector3MultiplyScalar(velocity, -1.5f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.1f];
        }

    };
    
    self.emitterBlocks = @[[blockA copy],[blockB copy],[blockC copy],[blockD copy]];
    
    float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    [self preparePointOfViewWithAspectRatio:aspect];
}

- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio{
    self.particleEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.f), aspectRatio, 0.1, 20.0);
    self.particleEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(0, 0, 1.0,
                         0, 0, 0,
                         0, 1.0, 0);
}
- (void)update{
    NSTimeInterval timeElapsed = 1.0f * (float)random() / (float)RAND_MAX/ (float)10;
    //上一次更新时间
//    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    //上一次绘制的时间
//    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
//    //第一次恢复时间
//    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
//    //上一次恢复时间
//    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
    self.particleEffect.elapsedSeconds += timeElapsed;
//    NSTimeInterval timeElapsed = self.particleEffect.elapsedSeconds;
    if (self.autoSpawnDelta < (self.particleEffect.elapsedSeconds - self.lastSpawnTime)) {
        self.lastSpawnTime = self.particleEffect.elapsedSeconds;
        void(^emitterBlock)(void) = [self.emitterBlocks objectAtIndex:self.currentEmitterIndex];
        emitterBlock();
    }
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.particleEffect prepareToDraw];
    [self.particleEffect draw];
}
- (IBAction)selectAction:(UISegmentedControl *)sender {
    self.currentEmitterIndex = sender.selectedSegmentIndex;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}

@end
