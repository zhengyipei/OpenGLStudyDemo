//
//  ZYPDrawingBoardSoundEffect.h
//  OpenGLDemo
//
//  Created by imac on 2020/12/14.
//  Copyright © 2020 imac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYPDrawingBoardSoundEffect : NSObject
{
    SystemSoundID _soundID;
}

+ (id)soundEffectWithContentsOfFile:(NSString *)aPath;
- (id)initWithContentsOfFile:(NSString *)path;
- (void)play;

@end

NS_ASSUME_NONNULL_END
