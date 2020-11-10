//
//  YRender.m
//  LLMetal
//
//  Created by keith on 2020/11/10.
//

#import "YRender.h"

@interface YRender ()

//我们用来渲染的设备(又名GPU)
@property(strong, nonatomic) id<MTLDevice> device;

// 我们的渲染管道有顶点着色器和片元着色器 它们存储在.metal shader 文件中
@property(strong, nonatomic) id<MTLRenderPipelineState> pipelineState;

//命令队列,从命令缓存区获取
@property(strong, nonatomic) id<MTLCommandQueue> commandQueue;

//当前视图大小,这样我们才可以在渲染通道使用这个视图
@property(nonatomic) vector_uint2 viewportSize;

@end

@implementation YRender

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        //1、获取GPU 设备
        self.device = mtkView.device;
        //2、加载项目中的metal文件
        //1）从bundle中获取.metal文件
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        //2）从库中加载顶点函数
        id<MTLFunction> vertexFun = [defaultLibrary newFunctionWithName:@"vertexShader"];
        //3）加载片元函数
        id<MTLFunction> fragmentFun = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        
        
        //3、配置用于创建渲染管道的描述符
        //1）创建管道描述符
        MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc]init];
        //2）给描述符起名字
        pipelineDes.label = @"myPipelineDes";
        //3）顶点函数，用于处理渲染过程中的各个顶点
        pipelineDes.vertexFunction = vertexFun;
        //4）片元函数，用于处理渲染过程中各个片段/片元
        pipelineDes.fragmentFunction = fragmentFun;
        //5）一组存储颜色数据的组件
        pipelineDes.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        
        //4、同时创建并返回 渲染关系状态对象
        NSError *error = NULL;
        self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDes error:&error];
        
        //判断
        if (!self.pipelineState) {
            //如果我们没有正确设置管道描述符，则管道状态创建可能失败
            NSLog(@"Failed to created pipeline state, error %@", error);
            return nil;
        }
        
        //5、通过 device 创建 命令队列
        self.commandQueue = [self.device newCommandQueue];
        }
    return self;
}

// MTKViewDelegate代理方法
- (void)drawInMTKView:(MTKView *)view {
    //1、顶点数据
    static const LLVertex triangleVertices[] = {
        //顶点,    RGBA 颜色值
        { {  0.5, -0.25, 0.0, 1.0 }, { 1, 0, 0, 1 } },
        { { -0.5, -0.25, 0.0, 1.0 }, { 0, 1, 0, 1 } },
        { { -0.0f, 0.25, 0.0, 1.0 }, { 0, 0, 1, 1 } },
    };
    
    
    //2、创建 命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    commandBuffer.label = @"myCommandBuffer";
    
    //3、创建 渲染描述符
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    //判断
    if (renderPassDescriptor != nil) {
        
        //4、根据描述符，创建 命令编码器
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        //命名
        renderEncoder.label = @"myEncoder";
        
        
        
        
        //5、设置可绘制区域，也就是渲染区域 视口
        /*
        typedef struct {
            double originX, originY, width, height, znear, zfar;
        } MTLViewport;
         */
        MTLViewport viewPort = { 0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0};
        [renderEncoder setViewport:viewPort];
        
        
        //6、设置渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        
        
        //7、把顶点数据 从oc中 发送给 metal的 顶点着色函数
        
        /*
         参数1：要传递数据的 内存指针
         参数2：要传递数据的 内存大小
         参数3：整数索引，要对应vertexShader函数中缓冲区属性限定符的索引
         ** 注意，这个方法使用的前提啊，数据大小不能超过4096个字节。超过了就要用其他方法了
         */
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:LLVertexInputIndexVertices];
        
        
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:LLVertexInputIndexViewportSize];
        
        
        
        //8、准备绘制，设置图元连接方式
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];
        
        
        //9、编码器生成的命令都已经完成，从MTLCommandBuffer中分离
        [renderEncoder endEncoding];
        
        
        //10、一旦框架缓冲区完成，使用当前可绘制的进度表，相当于提交渲染
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    //11、渲染，把命令缓冲区推送到GPU
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
