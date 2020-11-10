//
//  YRender.h
//  LLMetal
//
//  Created by keith on 2020/11/10.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
// 桥接文件
#import "YShaderTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface YRender : NSObject<MTKViewDelegate>

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
