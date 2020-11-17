//
//  GLSLView.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/17.
//

#import "GLSLView.h"
#import <OpenGLES/ES3/gl.h>

@interface GLSLView ()

//1、EAGL提供的绘制表面：CAEAGLLayer（属于核心动画的特殊图层的一种）
@property (nonatomic,strong) CAEAGLLayer *myEaglLayer;
//2、上下文
@property (nonatomic,strong) EAGLContext *myContext;
//3、渲染缓冲区
@property (nonatomic,assign) GLuint myColorRenderBuffer;
//4、帧缓冲区
@property (nonatomic,assign) GLuint myColorFrameBuffer;
//5、程序对象的id
@property (nonatomic,assign) GLuint myPrograme;

@end

@implementation GLSLView

- (void)layoutSubviews {
    //1、设置图层
    [self setUpLayer];
    
    //2、设置上下文
    [self setUpContext];
    
    //3、清空缓冲区
    [self deleteBuffers];
    
    //4、设置renderBuffer
    [self setUpRenderBuffer];
    
    //5、设置frameBuffer
    [self setUpframeBuffer];
    
    //6、开始绘制
    [self renderDraw];
}

#pragma mark - 1、设置图层
-(void)setUpLayer {
    
    //1、创建图层
    //注意，重写layerClass，将我们自定义的GLSLView的图层，从CALayer替换成CAEAGLLayer。要重写layerClass方法
    self.myEaglLayer = (CAEAGLLayer *)self.layer;
    
    //2、设置规格scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    //3、设置描述属性
    /*
     1)kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     
     2)kEAGLDrawablePropertyColorFormat   可绘制表面的内部颜色缓存区格式.
     
        kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位(默认)
        kEAGLColorFormatRGB565：16位RGB的颜色，
        kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
    self.myEaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @false,kEAGLDrawablePropertyRetainedBacking,
                                           kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,
                                           nil];
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}


#pragma mark - 2、设置上下文
- (void)setUpContext {
    //1、使用3.0版本初始化上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    //2、判断是否创建成功
    if (!context) {
        NSLog(@"context  failed!");
        return;
    }
    
    //3、设置图形上下文
    if(![EAGLContext setCurrentContext:context]){
        NSLog(@"currentContext  failed!");
        return;
    }
    
    self.myContext = context;
    
}


#pragma mark - 3、清空缓冲区
- (void)deleteBuffers {
    
    /*
     buffer分frameBuffer 和 renderBuffer两大类
     其中，frameBuffer 相当于 renderBuffer 的管理者
     
     frame buffer object 即称为FBO
     renderBuffer又分为3类：colorBuffer、depthBuffer、stencilBuffer
     */
    
    //1、删除renderBuffer
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    //2、删除frameBuffer
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}


#pragma mark - 4、设置renderBuffer
- (void)setUpRenderBuffer {
    
    //1、定义一个缓冲区id
    GLuint buffer;
    
    //2、申请一个缓冲区
    glGenRenderbuffers(1, &buffer);
    
    //3、赋值成全局变量
    self.myColorRenderBuffer = buffer;
    
    //4、将申请的id绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //5、将可绘制对象的CAEAGLLayer的存储  绑定到 renderBuffer对象。此处把context和layer绑定到一起了，一定要写
    //指定存储在 renderbuffer 中图像的宽高以及颜色格式（从myLayer中获取），并按照此规格为之分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglLayer];
    
}


#pragma mark - 5、设置frameBuffer
- (void)setUpframeBuffer {
    
    //1、定义id
    GLuint buffer;
    
    //2、申请一个和缓冲区
    glGenFramebuffers(1, &buffer);
    //3、赋值
    self.myColorFrameBuffer = buffer;
    //4、绑定
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //5、renderBuffer与frameBuffer绑定到一起
    /*
     1）生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     2）调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     3）将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
     */
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
}


#pragma mark - 6、开始绘制
- (void)renderDraw {
    
    //1、设置背景色&清空颜色缓冲区
    glClearColor(0.3, 0.45, 0.6, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2、设置视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //3、读取顶点和片元着色器地址
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"glslImage" ofType:@"vsh"];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"glslImage" ofType:@"fsh"];
    
    //4、加载shader，拿到progrme
    self.myPrograme = [self loadShaderWithVertexFile:vertexFile andFragmentFile:fragmentFile];
    
    //5、链接link
    glLinkProgram(self.myPrograme);
    
    //6、检测link
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    
    if (linkStatus == GL_FALSE) {
        //获取link失败的信息
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"program link error:%@",messageString);
        return;
    }
    
    //7、使用program
    glUseProgram(self.myPrograme);
    
    //8、设置顶点坐标、纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    //9、转存到顶点缓冲区
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //10、打开attribute通道,读取顶点数据
    //1）获取顶点数据通道id  注意第二个参数要和vsh中的变量一模一样
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    //2）设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    //3）设置读取方式
    /*
     参数1：index,顶点数据的索引
     参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
     参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
     参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
     参数5：stride,连续顶点属性之间的偏移量，默认为0；
     参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
     */
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL + 0);
    
    
    //11、读取纹理数据
    GLuint textCoordinate = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textCoordinate);
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    
    //12、加载纹理，解压图片
    [self setUpTexture:@"1.png"];
    
    //13、设置纹理采样器sampler2D
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    

    //14、绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //15、从渲染缓冲区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERER];
}


#pragma mark - 加载着色器shader，并且与程序附着，拿到最后的程序id
- (GLuint)loadShaderWithVertexFile:(NSString *)vertexFile andFragmentFile:(NSString *)fragmentFile {
    //1、定义顶点着色器对象、片元着色器对象
    GLuint verShader,fragShader;
    
    //2、创建一个程序对象
    GLuint program = glCreateProgram();
    
    //3、编译2个着色器
    /*
     编译的步骤一模一样，直接封装起来
     参数1：编译完存储的底层地址
     参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
     参数3：文件路径
     */
    [self compileShader:&verShader type:GL_VERTEX_SHADER filePath:vertexFile];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER filePath:fragmentFile];
    
    //4、把着色器附着到程序上
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //5、着色器附着之后就没啥用了 释放掉
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
    
}


#pragma mark - 编译着色器
- (void)compileShader:(GLuint *)shader type:(GLenum)type filePath:(NSString *)filePath {
    
    //1、读取着色器文件路径，转换成c语言字符串
    NSString *pathString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar* source = (GLchar*)[pathString UTF8String];
    
    //2、创建一个对应的shader
    *shader = glCreateShader(type);
    
    
    //3、将着色器源码 附着到着色器对象上
    /*
     参数1：shader,要编译的着色器对象 *shader
     参数2：numOfStrings,传递的源码字符串数量 1个
     参数3：strings,着色器程序的源码（真正的着色器程序源码）
     参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
     */
    glShaderSource(*shader, 1, &source, NULL);
    
    //4、把 着色器源代码 编译成 目标代码
    glCompileShader(*shader);

}


#pragma mark - 加载纹理，解压图片
- (GLuint)setUpTexture:(NSString *)imageName {
    
    //1、纹理解压缩
    CGImageRef spriImage = [UIImage imageNamed:imageName].CGImage;
    
    //2、判断图片有没有拿到
    if (!spriImage) {
        NSLog(@"load image faile");
        exit(1);
    }
    
    //3、创建一个上下文
    /*
    CGBitmapContextCreate
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    
    //1)拿到图片的宽高
    size_t width = CGImageGetWidth(spriImage);
    size_t height = CGImageGetHeight(spriImage);
    
    //2）拿到图片的大小
    GLubyte *spriData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //3）创建上下文 CGContextRef
    CGContextRef spriContext = CGBitmapContextCreate(spriData, width, height, 8, width*4, CGImageGetColorSpace(spriImage), kCGImageAlphaPremultipliedLast);
    
    
    //4、将图片绘制出来
    /*
    CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
    CGContextDrawImage
    参数1：绘图上下文
    参数2：rect坐标
    参数3：绘制的图片
    */
    //1)拿到坐标
    CGRect rect = CGRectMake(0, 0, width, height);
    //2）使用默认方式绘制
    CGContextDrawImage(spriContext, rect, spriImage);
    
    
    
    //5、画图完毕就释放上下文
    CGContextRelease(spriContext);
    
    
    //6、绑定纹理id （小技巧，如果只有一个纹理id，默认是0，就可以省略glGenTexture代码了）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //7、设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
 
    
    
    //8、载入2D纹理
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    float fw = width,fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriData);
    
    
    //9、释放spriData
    free(spriData);
    
    return 0;
    
}

@end
