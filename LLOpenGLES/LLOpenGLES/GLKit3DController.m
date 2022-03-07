//
//  GLKit3DController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/19.
//

#import "GLKit3DController.h"
#import <GLKit/GLKit.h>

@interface GLKit3DController ()

@property (nonatomic,strong) GLKView *glkView;
//着色器程序
@property (nonatomic,strong) GLKBaseEffect *myEffect;
//记录索引数组的个数
@property (nonatomic,assign) int ArrCount;

//记录旋转的角度
@property (nonatomic,assign) float XDegree;
@property (nonatomic,assign) float YDegree;
@property (nonatomic,assign) float ZDegree;

//记录是否开启旋转
@property (nonatomic,assign) BOOL XB;
@property (nonatomic,assign) BOOL YB;
@property (nonatomic,assign) BOOL ZB;
//是否开启纹理颜色混合
@property (nonatomic,assign) BOOL isHybrid;

@property(nonatomic,copy) dispatch_source_t timer;

@end

@implementation GLKit3DController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.isHybrid = NO;
    
    /*
     思路：
     1、初始化配置：
     1）context&当前上下文
     2）设置glkview
     3）开启深度测试
     2、设置数据
     1）初始化 顶点数据、索引数据
     2）把数据copy到缓冲区
     3）打开通道，读取需要传递的数据
     3、绘制
     1）初始化着色器effect
     2）是否加载纹理数据
     3）投影矩阵
     4）视图模型矩阵
     4、添加底部buttons
     5、开启定时器
     */
    
    //1、
    [self SetUpConfig];
    
    //2、
    [self SetUpVertexData];
    
    //3、
    [self drawPart];
    
    //4、
    [self setUpBottomButtons];
    
    //5
    [self addTimer];
    
}

#pragma mark - 1、初始化配置
-(void)SetUpConfig{
    
    //1、创建上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //2、设置当前上下文
    [EAGLContext setCurrentContext:context];
    
    //3、
    self.glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:context];
    self.glkView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self.view addSubview:self.glkView];
    //4、
    glEnable(GL_DEPTH_TEST);
    
}
#pragma mark - 2、设置数据
-(void)SetUpVertexData{
    
    //1.顶点数据
    //前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,       0.0f, 0.0f,//左下
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,       0.5f, 0.5f,//顶点
    };
    
    
    //索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //索引顶点个数
    self.ArrCount = sizeof(indices) / sizeof(GLuint);
    
    //2、把数据分别copy到缓冲区
    
    //顶点缓冲区
    GLuint vBuffer;
    glGenBuffers(1, &vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
    //拷贝数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    
    //索引缓冲区
    GLuint iBuffer;
    glGenBuffers(1, &iBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //3、打开通道，读取数据
    
    //顶点
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 0);
    
    //顶点颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    //纹理
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
}
#pragma mark - 3、绘制
-(void)drawPart{
    
    
    if (!self.myEffect) {
        
        self.myEffect = [[GLKBaseEffect alloc] init];
    }
    if (self.isHybrid == YES) {
        
        
        
        //获取图片路径
        NSString *imageFile = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        
        //翻转策略
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"1",GLKTextureLoaderOriginBottomLeft, nil];
        
        //获取纹理信息
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imageFile options:options error:nil];
        
        self.myEffect.texture2d0.enabled = GL_TRUE;
        
        self.myEffect.texture2d0.name = textureInfo.name;
        
        
    }else{
        
        self.myEffect.texture2d0.enabled = GL_FALSE;
    }
    
    
    //设置投影矩阵
    
    //宽高比
    float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 100.0f);
    
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.myEffect.transform.projectionMatrix = projectionMatrix;
    
    
    //设置视图模型矩阵
    //把物体往里移动10，改变单元矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.5f);
    self.myEffect.transform.modelviewMatrix = modelViewMatrix;
    
}

#pragma mark - 4、添加底部按钮，控制旋转、切换
-(void)setUpBottomButtons{
    
    NSArray *array = @[@"x",@"y",@"z",@"混合"];
    
#define AppViewW 50
#define AppViewH 50
#define KColCount 4 //每行的个数
    //每个Button的起始位置
#define KStartX 30
#define KStartY self.view.frame.size.height - 80
    //两个Button之间的间距
#define SpaceX 30
#define SpaceY 0
    
    
    for (int i=0; i<array.count;i++) {
        
        
        
        int row=i/KColCount;//行的信息
        int col=i%KColCount;//列的信息
        //计算每个appView的x和y值
        CGFloat x=KStartX + col*(AppViewW+SpaceX);
        CGFloat y=KStartY + row*(AppViewH+SpaceY);
        
        
        //创建一个button对象
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, y, AppViewW, AppViewH)];
        
        btn.backgroundColor = [UIColor cyanColor];
        
        [btn setTitle:array[i] forState:UIControlStateNormal];
        
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        
        if (i == 0) {
            [btn addTarget:self action:@selector(XClick:) forControlEvents:UIControlEventTouchUpInside];
        }else if (i == 1){
            [btn addTarget:self action:@selector(YClick:) forControlEvents:UIControlEventTouchUpInside];
        }else if (i == 2){
            [btn addTarget:self action:@selector(ZClick:) forControlEvents:UIControlEventTouchUpInside];
        }else if (i == 3){
            [btn addTarget:self action:@selector(HClick:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        
        // 添加到当前视图
        [self.glkView addSubview:btn];
        
        
    }
}


- (void)XClick:(UIButton *)sender {
    
    self.XB = !self.XB;
}
- (void)YClick:(UIButton *)sender {
    
    self.YB = !self.YB;
}
- (void)ZClick:(UIButton *)sender {
    
    self.ZB = !self.ZB;
}
- (void)HClick:(UIButton *)sender {
    
    self.isHybrid = !self.isHybrid;
    
    [self drawPart];
    
    //    if (self.isHybrid == NO) {
    //
    //        self.isHybrid = YES;
    //
    //        [self drawPart];
    //    }
    
    
}
-(void)addTimer
{
    
    //定时器
    double seconds = 0.1;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(_timer, ^{
        
        self.XDegree += 0.1f * self.XB;
        self.YDegree += 0.1f * self.YB;
        self.ZDegree += 0.1f * self.ZB ;
        
        //不需要调用刷新方法。因为在GLKVC中会有一个update方法去刷新
        
        NSLog(@"123");
    });
    dispatch_resume(_timer);
}


#pragma mark - glkView的代理方法
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.myEffect prepareToDraw];
    
    //使用索引绘图
    //1、图元连接方式
    //2、有几个数据
    //3、无符号整型
    //4、要是没放索引缓冲区就直接给它，这里我们放缓冲区了 不知道在哪，直接写0，让它自己去找
    glDrawElements(GL_TRIANGLES, self.ArrCount, GL_UNSIGNED_INT, 0);
}

#pragma mark - GLKViewController的刷新方法
- (void)update{
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -3.0f);
    
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.XDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.YDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.ZDegree);
    
    self.myEffect.transform.modelviewMatrix = modelViewMatrix;
    
}

@end
