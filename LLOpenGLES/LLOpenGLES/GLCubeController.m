//
//  GLSquareController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/13.
//

#import "GLCubeController.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

//这里数据的初始化方式是c语言中的结构体赋值
typedef struct {
    GLKVector3 positionCoord;//顶点坐标
    GLKVector2 textureCoord;//纹理坐标
    GLKVector3 normal;//法线
} YVertex;

@interface GLCubeController ()

@property (nonatomic,strong) GLKView *glkView;
@property (nonatomic,strong) GLKBaseEffect *effect;
@property (nonatomic,assign) YVertex *vertexArr;
@property (nonatomic,strong) CADisplayLink *disTimer;
@property (nonatomic,assign) NSInteger angle;
@property (nonatomic,assign) GLuint vertexBuffer;

@end

@implementation GLCubeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];

    [self setUpConfig];
    [self setUpVertexData];
    [self setUpTexture];
    [self addCADisplayLink];
}

- (void)setUpConfig {
    
    //1、上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    //2、设置当前上下文
    [EAGLContext setCurrentContext:context];
    
    //3、初始化GLKView
    self.glkView = [[GLKView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width) context:context];
    self.glkView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.glkView.backgroundColor = [UIColor clearColor];
    //4、设置GLKView的代理
    self.glkView.delegate = self;
    //5、设置深度缓冲区
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //6、设置深度缓冲区范围
    //默认是(0, 1)，这里用于翻转 z 轴，使正方形朝屏幕外
    glDepthRangef(1, 0);
    //7
    [self.view addSubview:self.glkView];
}

- (void)setUpVertexData{
    
    /*
    解释一下:
    这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点
    以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
    */
    
    //1、开辟顶点数据空间(数据结构SenceVertex 大小 * 顶点个数)
    self.vertexArr = malloc(sizeof(YVertex) * 36);
    
    //2、设置顶点数据
    //顶点坐标 + 纹理坐标 + 法线
    
    // 前面
    self.vertexArr[0] = (YVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
    self.vertexArr[1] = (YVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexArr[2] = (YVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexArr[3] = (YVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexArr[4] = (YVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexArr[5] = (YVertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};
    
    // 上面
    self.vertexArr[6] = (YVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
    self.vertexArr[7] = (YVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexArr[8] = (YVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexArr[9] = (YVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexArr[10] = (YVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexArr[11] = (YVertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};
    
    // 下面
    self.vertexArr[12] = (YVertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
    self.vertexArr[13] = (YVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexArr[14] = (YVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexArr[15] = (YVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexArr[16] = (YVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexArr[17] = (YVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};
    
    // 左面
    self.vertexArr[18] = (YVertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
    self.vertexArr[19] = (YVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexArr[20] = (YVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexArr[21] = (YVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexArr[22] = (YVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexArr[23] = (YVertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};
    
    // 右面
    self.vertexArr[24] = (YVertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
    self.vertexArr[25] = (YVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexArr[26] = (YVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexArr[27] = (YVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexArr[28] = (YVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexArr[29] = (YVertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};
    
    // 后面
    self.vertexArr[30] = (YVertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
    self.vertexArr[31] = (YVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexArr[32] = (YVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexArr[33] = (YVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexArr[34] = (YVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexArr[35] = (YVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};
    
    
    
    //3、开辟顶点缓冲区
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(YVertex) * 36, self.vertexArr, GL_STATIC_DRAW);
    
    //4、开启读取通道
    //sizeof(YVertex) 步长就是一个结构体
    //offsetof(YVertex, positionCoord) 偏移到从结构体中positionCoord的位置开始读取
    //顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(YVertex), NULL + offsetof(YVertex, positionCoord));
    
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(YVertex), NULL + offsetof(YVertex, textureCoord));
    
    
    //法线数据
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(YVertex), NULL + offsetof(YVertex, normal));
}

- (void)setUpTexture {
    
    //1、获取纹理图片
    //相比上个案例换一种写法
    NSString *filePath = [[[NSBundle mainBundle]resourcePath ] stringByAppendingPathComponent:@"1.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    //2、设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:nil];
    
    //3、使用baseEffect进行着色
    self.effect = [[GLKBaseEffect alloc]init];
    self.effect.texture2d0.name = textureInfo.name;
    self.effect.texture2d0.target = textureInfo.target;
    
    //4、开启光照效果
    self.effect.light0.enabled = YES;
    //6、漫反射颜色
    self.effect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    //7、设置光源位置
    self.effect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

    //1、清楚颜色&深度 缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //2、开启深度测试
    glEnable(GL_DEPTH_TEST);
    //3、准备绘制
    [self.effect prepareToDraw];
    //4、开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

- (void)addCADisplayLink {
    self.angle = 0;
    self.disTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerUpDate)];
    [self.disTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)timerUpDate {
    
    //1、计算旋转角度 （每次匀速+5度，但是不能超过360度，否则转的太快）
    self.angle = (self.angle + 5) % 360;
    
    //2、修改effect的矩阵
    self.effect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.5, 0.7, 0.3);
    
    //3、重新渲染
    [self.glkView display];
    
}
-(void)dealloc {
    
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }

    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    if (_vertexArr) {
        free(_vertexArr);
        _vertexArr = nil;
    }
    
    [self.disTimer invalidate];
}



@end
