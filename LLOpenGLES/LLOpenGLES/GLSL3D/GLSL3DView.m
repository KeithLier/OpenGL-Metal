//
//  GLSL3DView.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/18.
//

#import "GLSL3DView.h"
#import <OpenGLES/ES3/gl.h>
//导入工具类
//#import "GLESMath.h"
//#import "GLESUtils.h"
#import <GLKit/GLKit.h>

@interface GLSL3DView() {
    //这里的东西是用来控制旋转操作的参数
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
    
    BOOL isHybrid;
}
//EAGL提供的绘制表面
@property (nonatomic,strong) CAEAGLLayer *myEaglLayer;
//上下文
@property (nonatomic,strong) EAGLContext *myContext;
//渲染缓冲区
@property (nonatomic,assign) GLuint myColorRenderBuffer;
//帧缓冲区
@property (nonatomic,assign) GLuint myColorFrameBuffer;
//程序对象的id
@property (nonatomic,assign) GLuint myPrograme;
//顶点缓冲区id
@property (nonatomic , assign) GLuint myVertices;

@end

@implementation GLSL3DView

 
- (void)layoutSubviews {
    
    isHybrid = NO;
    
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
    
    //7、添加底部按钮，控制旋转、切换
    [self setUpBottomButtons];
    
}
#pragma mark - 1、设置图层
-(void)setUpLayer{
    
    //1、创建图层
    self.myEaglLayer = (CAEAGLLayer *)self.layer;
    self.myEaglLayer.opaque = YES;
    //2、设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    //3、设置描述属性
    self.myEaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @false,kEAGLDrawablePropertyRetainedBacking,
                                           kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,
                                           nil];

}
+(Class)layerClass{
    return [CAEAGLLayer class];
}

#pragma mark - 2、设置上下文
-(void)setUpContext{
    //初始化上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //判断
    if (!context) {
        NSLog(@"上下文创建失败");
        return;
    }
    //设置当前上下文
    [EAGLContext setCurrentContext:context];
    self.myContext = context;
}

#pragma mark - 3、清空缓冲区
-(void)deleteBuffers{
 
    //清空渲染缓冲区
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    //清空帧缓冲区
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    
}
#pragma mark - 4、设置renderBuffer
-(void)setUpRenderBuffer{
    
    //定义一个缓冲区id
    GLuint rBuffer;
    //申请一个缓冲区
    glGenRenderbuffers(1, &rBuffer);
    self.myColorRenderBuffer = rBuffer;
    //绑定渲染缓冲区
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    //把layer的存储 绑定到 渲染缓冲区。此处也把context与layer绑定在一起
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglLayer];
    
}

#pragma mark - 5、设置frameBuffer
-(void)setUpframeBuffer{
    
    GLuint *fBuffer;
    glGenFramebuffers(1, &fBuffer);
    self.myColorFrameBuffer = fBuffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    //把renderBuffer和frameBuffer绑定在一起.把renderBuffer绑定到GL_COLOR_ATTACHMENT0上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    
}
#pragma mark - 6、开始绘制
-(void)renderDraw{
    
    //1、设置背景色&清空颜色缓冲区
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2、设置视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //3、读取2个着色器地址
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"glsl3d" ofType:@"vsh"];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"glsl3d" ofType:@"fsh"];
    
    //4、编译加载shader，并附着到程序上，拿到程序id
    //**注意** 有可能一个项目中有多个程序。严谨一点 先判断
    if (self.myPrograme) {
        glDeleteProgram(self.myPrograme);
        self.myPrograme = 0;
    }
    self.myPrograme = [self loadShaderWithVertexFile:vertexFile andFragmentFile:fragmentFile];
    
    //5、连接link
    glLinkProgram(self.myPrograme);
    
    //6、检验link
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    
    if (linkStatus == GL_FALSE) {
        //定义一个c语言字符串接受失败信息,不知道信息有多大，尽量写大一点，这里写了512
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        //转成oc字符串并打印信息
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"link失败信息：%@",messageString);
        return;
    }
    
    
    //7、使用program
    glUseProgram(self.myPrograme);
    

    //========================================================================================================
    //**注意**| 这里开始就与之前加载2D图片有所区别了 |**注意**
    //========================================================================================================
    //8.创建顶点数组 & 索引数组
    //(1)顶点数组 前3顶点值（x,y,z），中间3位颜色值(RGB)，后面2位是纹理（s，t）
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    
    //9、从数组copy到缓冲区
    //1）因为用了定时器会不断刷新，先判断缓冲区是否为空，为空再申请id
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    //2）绑定到顶点缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //3）从内存copy到显存
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //10、打开通道，传递顶点数据
    GLint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL + 0);
    
    //11、打开通道，传递颜色数据
    GLint positionColor = glGetAttribLocation(self.myPrograme, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL + 3);
    
    //开关控制是否混合纹理和颜色
    if (isHybrid == YES) {
        //12、打开通道，传递纹理数据
        GLint textCoor = glGetAttribLocation(self.myPrograme, "textCoor");
        glEnableVertexAttribArray(textCoor);
        glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL + 6);
        
        //13、加载纹理
        [self setUpTexture:@"1.png"];
        
        //14、设置纹理采样器 sampler2D   整个OpenGL中能有16个纹理id，默认0是第一个
        glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
        
    }
    
    //15、先找到program中投影矩阵、视图模型矩阵的地址。如果找不到返回-1 表示没有找到这2个对象
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myPrograme, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myPrograme, "modelViewMatrix");
    
    
    //16、投影矩阵 :决定了是正投影还是透视投影
    //1）创建一个4*4的投影矩阵
    GLKMatrix4 _projectionMatrix = GLKMatrix4Identity;
    //2）获取单元矩阵
//    ksMatrixLoadIdentity(&_projectionMatrix);
    //3）计算纵横比
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height;
    //4）获取投影矩阵
    _projectionMatrix = GLKMatrix4MakePerspective(30.0, aspect, 5.0f, 30.0f);
//    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 30.0f);
    //5）把投影矩阵传递到顶点着色器
    /*
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m);
    
    
    //17、视图模型矩阵 ： 决定了 金字塔是怎么移动旋转的
    //1）创建一个4*4的矩阵
    GLKMatrix4 _modelViewMatrix = GLKMatrix4Identity;
    //2）获取单元矩阵
//    ksMatrixLoadIdentity(&_modelViewMatrix);
    //3）平移，z轴移动-10    相当于OpenGL中setUpRC()中，设置物体位置一样
    GLKMatrix4Translate(_modelViewMatrix, 0.0, 0.0, -10.0);
//    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    //4）创建一个旋转矩阵     这里相当于OpenGL中RenderSence()中，记录模型变化的地方一样
    GLKMatrix4 _rotationMatrix = GLKMatrix4Identity;
    //5）加载一个单元矩阵
//    ksMatrixLoadIdentity(&_rotationMatrix);
    //6）旋转
    GLKMatrix4Rotate(_rotationMatrix, xDegree, 1.0, 0.0, 0.0);
    GLKMatrix4Rotate(_rotationMatrix, yDegree, 0.0, 1.0, 0.0);
    GLKMatrix4Rotate(_rotationMatrix, zDegree, 0.0, 0.0, 1.0);
//    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0);
//    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0);
//    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0);
    //7）把最终的 旋转矩阵 和 模型视图矩阵 相乘，结果放到模型视图矩阵中
    GLKMatrix4Multiply(_modelViewMatrix, _rotationMatrix);
//    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    //8）把模型视图矩阵传递到顶点着色器中
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, &_modelViewMatrix.m);

    
    //18、开启正背面剔除
    glEnable(GL_CULL_FACE);
    
    //18、索引绘图
    /*
    void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
    参数列表：
    mode:要呈现的画图的模型
               GL_POINTS
               GL_LINES
               GL_LINE_LOOP
               GL_LINE_STRIP
               GL_TRIANGLES
               GL_TRIANGLE_STRIP
               GL_TRIANGLE_FAN
    count:绘图个数
    type:类型
            GL_BYTE
            GL_UNSIGNED_BYTE
            GL_SHORT
            GL_UNSIGNED_SHORT
            GL_INT
            GL_UNSIGNED_INT
    indices：绘制索引数组

    */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    
    //19、渲染到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

 

#pragma mark -第6步需要的  封装方法
#pragma mark - 编译加载着色器shader，并且与程序附着，拿到最后的程序id
-(GLuint)loadShaderWithVertexFile:(NSString *)vertexFile andFragmentFile:(NSString *)fragmentFile {

    //定义着色器对象
    GLuint verShader,fragShader;
    //创建程序对象
    GLuint program = glCreateProgram();
    
    //编译着色器
    [self compileShader:&verShader type:GL_VERTEX_SHADER filePath:vertexFile];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER filePath:fragmentFile];
    
    //拿到了着色器对象，附着到程序上
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //附着完成，拿到了程序id，着色器就可以释放了
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

#pragma mark - 编译着色器
-(void)compileShader:(GLuint *)shader type:(GLenum)type filePath:(NSString *)filePath{
 
    //1 读取着色器的路径，转换成c语言字符串
    NSString *pathString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar *source = (GLchar *)[pathString UTF8String];
    
    //2、根据类型创建着色器
    *shader = glCreateShader(type);
    
    //3、把着色器字符串的源码，放到着色器对象里面
    glShaderSource(*shader, 1, &source, NULL);
    
    //4、编译(把我们写的着色器源代码 编译成 目标代码，也就是shader就完成了)
    glCompileShader(*shader);
}


#pragma mark - 加载纹理，解压图片 === 这里也是图片解压缩的原理
-(GLuint)setUpTexture:(NSString *)imageName{
 
    //1、纹理解压缩
    CGImageRef spriImage = [UIImage imageNamed:imageName].CGImage;
    //2、判断图片有没有拿到
    if (!spriImage) {
        NSLog(@"图片没有拿到");
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
    //1）拿到图片的宽高
    size_t width = CGImageGetWidth(spriImage);
    size_t height = CGImageGetHeight(spriImage);
    
    //2）拿到图片的大小，也就是纹理数据
    GLubyte *spriData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //3）创建上下文
    CGContextRef spriContext = CGBitmapContextCreate(spriData, width, height, 8, width*4, CGImageGetColorSpace(spriImage), kCGImageAlphaPremultipliedLast);
    
    //4、将图片绘制出来
    //1）拿到坐标
    CGRect rect = CGRectMake(0, 0, width, height);
    //2）使用默认方式绘制
    CGContextDrawImage(spriContext, rect, spriImage);
    //3）翻转策略
    CGContextTranslateCTM(spriContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriContext, 0, rect.size.height);
    CGContextScaleCTM(spriContext, 1.0, -1.0);
    CGContextTranslateCTM(spriContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriContext, rect, spriImage);
    
    //5、绘制完成，释放上下文
    CGContextRelease(spriContext);
    
    //6、绑定纹理id(如果只有一个纹理，直接使用0就行了)
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //7、设置纹理的缩放和环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //8、载入2D纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriData);
    
    //9、释放纹理数据
    free(spriData);
    
    return 0;
}

#pragma mark - 7、添加底部按钮，控制旋转、切换
-(void)setUpBottomButtons{
    
    NSArray *array = @[@"x",@"y",@"z",@"混合"];
    
#define AppViewW 50
#define AppViewH 50
#define KColCount 4 //每行的个数
    //每个Button的起始位置
#define KStartX 30
#define KStartY self.frame.size.height - 80
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
        [self addSubview:btn];
        
        
    }
}


- (void)XClick:(UIButton *)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bX = !bX;
    
}
- (void)YClick:(UIButton *)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bY = !bY;
}
- (void)ZClick:(UIButton *)sender {
    
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bZ = !bZ;
}
- (void)HClick:(UIButton *)sender {
     
    isHybrid = YES;
    if (!myTimer) {
        //重新渲染
        [self renderDraw];
    }
}
-(void)reDegree
{
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self renderDraw];
    
}


@end
