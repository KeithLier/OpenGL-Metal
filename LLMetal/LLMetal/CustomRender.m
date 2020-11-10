//
//  CuntomRender.m
//  LLMetal
//
//  Created by keith on 2020/11/6.
//

#import "CustomRender.h"

@interface CustomRender ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

@implementation CustomRender

typedef struct {
    float red, green, blue, alpha;
} Color;

- (id)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        // 传参
        self.device = mtkView.device;
        
        // 通过device 创建commandQueue
        self.commandQueue = [self.device newCommandQueue];
    }
    return  self;
}

// 设置颜色
- (Color)makeFancyColor {
    // 1.增加/减少颜色的标记
    static BOOL growing = YES;
    // 2.颜色的通道值（0~3）
    static NSUInteger primaryChannel = 0;
    // 3.颜色的通道值数组
    static float colorChannels[] = {1.0, 0.0, 0.0, 1.0};
    // 4.颜色调整步长
    const float dynamicColorRate = 0.015;
    
    // 5.判断
    if (growing) {
        // 动态信道索引 (1,2,3,0)通道间切换
        NSUInteger dynamicChannelIndex = (primaryChannel + 1) % 3;
        // 修改对应通道的颜色值 调整0.015
        colorChannels[dynamicChannelIndex] += dynamicColorRate;
        // 当颜色通道对应的颜色值 = 1.0
        if (colorChannels[dynamicChannelIndex] >= 1.0) {
            growing = NO;
            //将颜色通道修改为动态颜色通道
            primaryChannel = dynamicChannelIndex;
        }
    } else {
        // 获取动态颜色通道
        NSUInteger dynamicChannelIndex = (primaryChannel + 2) % 3;
        //将当前颜色的值 减去0.015
        colorChannels[dynamicChannelIndex] -= dynamicColorRate;
        // 当颜色值小于等于0.0
        if (colorChannels[dynamicChannelIndex] <= 0.0) {
            growing = YES;
        }
    }
    
    // 创建颜色
    Color color;
    color.red = colorChannels[0];
    color.green = colorChannels[1];
    color.blue= colorChannels[2];
    color.alpha = colorChannels[3];
    
    return color;
}

// 代理
- (void)drawInMTKView:(MTKView *)view {
    // 1.获取颜色
    Color color = [self makeFancyColor];
    // 2.设置view的clearColor
    view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
    
    
    // 1.使用Queue创建对象，并添加到buffer对象中
    id<MTLCommandBuffer> buffer = [self.commandQueue commandBuffer];
    // 2. 获取渲染描述符
    MTLRenderPassDescriptor *renderPassDesc = view.currentRenderPassDescriptor;
    // 3.判断，不成功则跳过渲染
    if (renderPassDesc != nil) {
        // 4.通过 渲染描述符 创建 渲染编码器对象
        id<MTLRenderCommandEncoder> renderEncoder = [buffer renderCommandEncoderWithDescriptor:renderPassDesc];
        // 5.给渲染编码器命名
        renderEncoder.label = @"myEncoder";
        // 6.这里可以执行metal需要处理的渲染
        
        
        // 7.结束编码
        [renderEncoder endEncoding];
        
        /*
         当编码器结束之后,命令缓存区就会接受到2个命令.
         1) present
         2) commit
         因为GPU是不会直接绘制到屏幕上,因此你不给出去指令.是不会有任何内容渲染到屏幕上.
        */
        // 8.添加最后一个命令来显示可清除的可绘制的屏幕
        [buffer presentDrawable:view.currentDrawable];
    }
    
    // 9.完成渲染并将命令缓冲区提交给GPU
    [buffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

@end
