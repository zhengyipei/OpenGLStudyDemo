//
//  ZYPSkyBoxEffect.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/14.
//  Copyright © 2021 imac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/ES2/glext.h>
NS_ASSUME_NONNULL_BEGIN
//GLKNamedEffect 提供基于着色器的OpenGL渲染效果的对象的标准接口
@interface ZYPSkyBoxEffect : NSObject<GLKNamedEffect>

@property (nonatomic,assign) GLKVector3 center;
@property (nonatomic,assign) GLfloat xSize;
@property (nonatomic,assign) GLfloat ySize;
@property (nonatomic,assign) GLfloat zSize;

@property (nonatomic,strong,readonly) GLKEffectPropertyTexture *textureCubeMap;
@property (nonatomic,strong,readonly) GLKEffectPropertyTransform *transform;

- (void)prepareToDraw;

- (void)draw;

@end

NS_ASSUME_NONNULL_END
