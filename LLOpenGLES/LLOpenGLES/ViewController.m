//
//  ViewController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/12.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface ViewController ()<GLKViewDelegate>

@property (strong, nonatomic) GLKBaseEffect *yEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupConfig];
    [self setupVertexData];
    [self setupTexture];
}

// 初始化配置信息
- (void)setupConfig {
    // 1.初始化上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    //2、检测一下
    if(!context){
        NSLog(@"context failed !!!");
    }
    //3、设置当前的上下文（因为上下文可以存在多个，但是当前上下文只有一个）
    [EAGLContext setCurrentContext:context];
    
    //4、初始化GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    
    //5、设置背景颜色
    glClearColor(0.5f, 0.5f, 0.0f, 1.0f);
    
    //6、配置视图创建的渲染缓冲区
    /*
     drawableColorFormat: 颜色缓存区格式.它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个像素的颜色格式。
     
     GLKViewDrawableColorFormatRGBA8888 = 0,
     默认.缓存区的每个像素的最小组成部分（RGBA）使用8个bit，（所以每个像素4个字节，4*8个bit）。
     
     GLKViewDrawableColorFormatRGB565,
     如果你的APP允许更小范围的颜色，即可设置这个。会让你的APP消耗更小的资源（内存和处理时间）
     
     GLKViewDrawableColorFormatSRGBA8888
     */
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    
    /*
     drawableDepthFormat: 深度缓存区格式
     
     GLKViewDrawableDepthFormatNone = 0,意味着完全没有深度缓冲区
     GLKViewDrawableDepthFormat16,这个会相比24消耗更少的资源
     GLKViewDrawableDepthFormat24,一般用于3D游戏
     */
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    //还要记得GLKView的代理
    view.delegate = self;
}

// 设置顶点数据和纹理坐标
- (void)setupVertexData {
    //1、设置顶点数组
    /*
     1)由2个三角形组成
     2）根据纹理坐标，图片左下角是（0，0）
     */
    GLfloat vertexData[] = {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5,  0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    //2、为了GPU更高效，把内存拷贝到显存中--->开辟顶点缓冲区
    //1）创建顶点缓冲区标识符id
    GLuint vbufferId;
    glGenBuffers(1, &vbufferId);
    //2)绑定顶点缓冲区（明确作用）
    glBindBuffer(GL_ARRAY_BUFFER, vbufferId);
    //3)把顶点数组里的数据copy到顶点缓冲区
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    
    //3、打开读取通道
    //Attributes默认是关闭的。通过api开启，需要开启两次，分别传入顶点数据和纹理数据
    /*
     (1)在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
     意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
     所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
     注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     
     (2)方法简介
     glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
     
     功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
     参数列表:
     index,指定要修改的顶点属性的索引值,例如
     size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
     type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
     normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
     stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
     ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
     */
    
    //顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) *5, (GLfloat *)NULL + 0);
    
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

// 加载纹理数据
- (void)setupTexture {
    //1、获取纹理图片的路径
    NSBundle *filePath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
    
    //2、设置纹理参数
    //纹理坐标原点是左下角，但 图片显示原点是在左上角
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //3、使用effect完成着色器工作
    self.yEffect = [[GLKBaseEffect alloc] init];
    self.yEffect.texture2d0.enabled = GL_TRUE;
    self.yEffect.texture2d0.name = textureInfo.name;
    
    //注意，绘制工作在GLKView的代理方法中完成
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //这个方法其实相当于RenderSence
    //1、清理缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    //2、准备绘制
    [self.yEffect prepareToDraw];
    
    //3、绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
