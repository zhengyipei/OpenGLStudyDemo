//
//  ZYPPointParticleEffect.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/18.
//  Copyright © 2021 imac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const GLKVector3 mDefaultGravity;

@interface ZYPPointParticleEffect : NSObject

//重力
@property (nonatomic,assign) GLKVector3 gravity;
//耗时
@property (nonatomic,assign) GLfloat elapsedSeconds;
//纹理
@property (nonatomic,strong,readonly) GLKEffectPropertyTexture *texture2d0;
//变换
@property (nonatomic,strong,readonly) GLKEffectPropertyTransform *transform;
//添加粒子
/*
 aPosition:位置
 aVelocity:速度
 aForce:重力
 aSize:大小
 aSpan:跨度
 aDuration:时长
 */
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)size
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

- (void)prepareToDraw;

- (void)draw;
@end

NS_ASSUME_NONNULL_END
