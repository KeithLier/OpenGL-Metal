//
//  CuntomRender.h
//  LLMetal
//
//  Created by keith on 2020/11/6.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomRender : NSObject<MTKViewDelegate>

- (id)initWithMetalKitView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
