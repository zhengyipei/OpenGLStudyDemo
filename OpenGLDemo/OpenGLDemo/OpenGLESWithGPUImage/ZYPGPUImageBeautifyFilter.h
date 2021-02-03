//
//  ZYPGPUImageBeautifyFilter.h
//  OpenGLDemo
//
//  Created by imac on 2021/1/28.
//  Copyright © 2021 imac. All rights reserved.
//

#import "GPUImageFilterGroup.h"
#import <GPUImage/GPUImage.h>
NS_ASSUME_NONNULL_BEGIN

@class GPUImageCombinationFilter;

@interface ZYPGPUImageBeautifyFilter : GPUImageFilterGroup
{
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageCombinationFilter *combinationFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end

NS_ASSUME_NONNULL_END
