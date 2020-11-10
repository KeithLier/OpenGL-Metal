# 一、Metal简介
### 1、Metal

> 早在2014年的WWDC大会上，Apple为游戏开发者推出了新的平台技术 Metal，该技术能够为 3D 图像提高 10 倍的渲染性能，并支持大家熟悉的游戏引擎及公司。

在2018年之前,OpenGL ES只能通过GPU进行图形的处理，无法调度GPU进行项目中高度的自定义的并发运算。但是在Metal中，苹果给了这样的入口，可以充分调用GPU来完成这件事情。
于是，在2018年，苹果做出了这样的决定：将原先CoreAnimation的内核从OpenGL ES迁移到了Metal。至此，我们可以在iOS设备上利用Metal来处理业务，就能最大限度的利用其GPU的性能。
换而言之，当我们需要进行高并发运算的时候，也要用到Metal来实现。就是因为Metal中有调用GPU来执行计算的入口。(比如AVFoundation的人脸识别功能，音视频的编码（压缩）和解码（解压缩），都需要用到GPU来达到高并发最好的效果)
需要注意：大多Metal程序，是不支持模拟器执行的，需要真机去执行。因此，对于真机也有要求：A7以上的处理器，也就是6s及以后的手机。

### 2、特点


CPU的开销非常低
发挥GPU的最佳性能（主要还是苹果自己调用自己的硬件更加得心应手）
最大限度提高CPU/GPU的并发性
更加有效的管理我们的资源

### 3、图形管道

大致和OpenGL ES没啥区别，最多就是 Shader改了个名字，叫Processing。
CPU部分： 处理顶点数据，传给顶点程序（着色器）
GPU部分：

顶点着色器处理CPU传过来的顶点数据，进行一系列坐标转换、裁剪 ↓
进行图元装配 ↓
光栅化 ↓
片元程序（着色器）去处理纹理、透明度、深度等 ↓
把最终数据存储到帧缓冲区，并显示到屏幕上

需要注意的是：
OpenGL ES的图元连接方式有9种：点、线、线段、线环、四边形、四边形带、三角形、三角形带、三角形扇
而Metal只有5种:点、线段、线环、三角形、三角形扇
### 4、Metal的使用建议


Separate Your Rendering Loop:分开渲染循环，苹果不希望渲染的处理放在VC中，希望我们可以把与Metal有关的渲染循环封装到一个单独的类中


Respond to View Events:响应视图的方法，也就是我们要遵循在单独的渲染类中遵循MTKViewDelegate的协议，实现2个代理方法


Metal Command Objects:命令对象，也就是我们要使⽤MTLCommandQueue创建对象并且加⼊到MTCommandBuffer对象中去，然后与GPU进行交互


### 5、Metal命令对象之间的关系


命令缓存区(command buffer) 是从命令队列(command queue) 创建的
命令编码器(command encoders) 将命令编码到命令缓存区中
提交命令缓存区并将其发送到GPU
GPU执⾏命令并将结果呈现为可绘制

# 二、Metal的相关API
### 1、MTKView

官方文档《MTKView》

与GLKit中提供的GLKView类似。Metal为我们提供的是MTKView，继承自UIView，用于处理metal绘制并显示到屏幕过程中的细节。
MTKView *view = [[MTKView alloc] init];
复制代码
### 2、MTLDevice

MTLDevice对象表示可以执行命令的GPU。MTLDevice协议具有：

创建新命令队列、 从内存中分配缓冲区、   创建纹理、  查询设备功能的方法。

要获得系统上的首选系统设备，请调用MTLCreateSystemDefaultDevice函数。

官方文档《The Device Object Represents a GPU》
一个MTLDevice对象就代表这着一个GPU,通常我们可以调用方法MTLCreateSystemDefaultDevice()来获取代表默认的GPU单个对象。其实也相当于我们要获取一个操作GPU的使用权限。
注意：MTKView必须设置MTLDevice。
//创建一个默认的device
view.device = MTLCreateSystemDefaultDevice();

//判断是否设置成功，因为后面有很多地方需要用到device，如果不成功就没什么意义了
if (!view.device) {
    NSLog(@"Metal is not supported on this device");
    return;
}
复制代码
### 3、MTLCommandQueue

官方文档《命令队列》

前提是MTLDevice创建成功，在获取了GPU之后，还需要一个渲染队列MTLCommandQueue，这个队列是与GPU交互的第一个对象，队列MTLCommandQueue中存储的是将要进行渲染的命令MTLCommandBuffer。
每个命令队列的生命周期很长，因此commandQueue可以重复使用，而不是频繁创建和销毁。
//通过 MTLDevice 创建 MTLCommandQueue
id<MTLCommandQueue> commandQueue = [view.device newCommandQueue];
复制代码
### 4、MTLCommandBuffer

官方文档《命令缓冲区》

命令缓冲区主要是用于存储编码的命令，其生命周期是直到缓冲区被提交到GPU执行为止，单个的命令缓冲区可以包含不同的编码命令，主要取决于用于构建它的编码器的类型和数量。
//通过 MTLCommandQueue 创建 MTLCommandBuffer
id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//给commandBuffer起个名字
commandBuffer.label = @"MyCommand";
复制代码
MTLCommandBuffer对象的提交，是提交到MTLCommandQueue对象中的。只有在提交后开始执行，通过入队顺序执行。有两种执行方式：

enqueue ： 顺序执行
commit ： 插队尽快执行，如果前面有commit还是需要排队等着

### 5、MTLRenderCommandEncoder

官方文档《命令编码器》

命令编码器表示单个渲染过程中相关联的渲染状态和渲染命令，有以下功能：

指定图形资源，例如缓存区和纹理对象，其中包含顶点、片元、纹理图片数据
指定一个MTLRenderPipelineState对象，表示编译的渲染状态，包含顶点着色器和片元着色器的编译&链接情况
指定固定功能，包括视口、三角形填充模式、剪刀矩形、深度、模板测试以及其他值
绘制3D图元

MTLRenderCommandEncoder的创建，需要渲染描述符MTLRenderPassDescriptor

//1.从视图绘制中,获得渲染描述符
MTLRenderPassDescriptor *renderPassDescriptor =  view.currentRenderPassDescriptor;
    
//2.判断renderPassDescriptor 渲染描述符是否创建成功,否则则跳过任何渲染.
if(renderPassDescriptor != nil)
{
    //3.创建MTLRenderCommandEncoder 对象
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    //4.给Encoder命名
    renderEncoder.label = @"MyRenderEncoder";

	//5.一些Metal文件的绘制操作
    //...
    
    //6.结束工作
    [renderEncoder endEncoding];
 
}


复制代码
### 6、MTKViewDelegate

//设置MTKView 的代理(由自定义的CustomRender来实现MTKView 的代理方法)
view.delegate = render;
    
//视图可以根据视图属性上设置帧速率(指定时间来调用drawInMTKView方法--视图需要渲染时调用)也就是每60帧刷新一次屏幕
view.preferredFramesPerSecond = 60;


//每当视图需要渲染时调用
- (void)drawInMTKView:(nonnull MTKView *)view;

//当MTKView视图发生大小改变时，或者重新布局时调用
 - (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size;
 
复制代码

