//
//  main.cpp
//  LLOpenGL
//
//  Created by keith on 2020/11/4.
//


#include "GLShaderManager.h"
/*
 GLShaderManager.h文件中移入了GLTool着色器管理器（shaderManager）类。
 没有着色器，我们就不能再openGL(核心框架)进行着色。着色器管理器不仅允许我们创建并管理着色器，还提供一组'存储着色器'，他们能够进行一些初步的基础的渲染操作
 */

#include "GLTools.h"
/*
 GLTools.h文件包含了大部分GLTool中类似c语言的独立函数
 */

#include <GLUT/GLUT.h>
/*
 在mac系统下，直接#include <GLUT/GLUT.h>
 在Windows和Linux上，我们使用freeglut的静态库版本并且需要添加一个宏
 */


//定义一个着色管理器
GLShaderManager shaderManager;
//简单的批次容器，是GLTools的一个简单的容器类
GLBatch triangleBatch;

/*
 自定义函数，通过glutReshaperFunc函数注册为重塑函数,相当于回调函数
 触发条件：1、新建窗口  2、窗口尺寸发生调整
 处理业务：1、设置视口  2、设置投影方式
 */
void changeSize(int w,int h)
{
    //x、y参数代表窗口中视图左下角的坐标，w、h是宽度、高度是以像素为表述的。通常x、y都是0
    glViewport(0, 0, w, h);
}

/*
 自定义函数，通过glutDisplayFunc函数注册为显示渲染函数,相当于回调函数
 当屏幕发生变化或者主动渲染时调用，用来实现数据显示渲染到屏幕的过程
 触发条件：1、系统自动触发  2、手动调用函数触发
 处理业务：1、清除缓存区  2、使用存储着色器  3、绘制图形
 */
void RenderScene(void)
{

    //1、清楚一个或一组特定缓存区
    /*
    缓冲区是一块存在图像信息的储存空间，红色、绿色、蓝色和alpha分量通常一起分量通常一起作为颜色缓存区或像素缓存区引用。
    OpenGL 中不止一种缓冲区（颜色缓存区、深度缓存区和模板缓存区）
     清除缓存区对数值进行预置
    参数：指定将要清除的缓存的
    GL_COLOR_BUFFER_BIT :指示当前激活的用来进行颜色写入缓冲区
    GL_DEPTH_BUFFER_BIT :指示深度缓存区
    GL_STENCIL_BUFFER_BIT:指示模板缓冲区
    */
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
    
    
    
    //2、设置颜色
    GLfloat vColor[] = {1.0,1.0,0.0,1.0f};
    
    //3、传递到存储着色器中
    //GLT_SHADER_IDENTITY着色器：使用指定颜色以默认笛卡尔坐标系在屏幕上渲染几何图形
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY,vColor);
    
    //4、提交着色器
    triangleBatch.Draw();
    
    //5、将后台缓冲区进行渲染，渲染结束后交换给前台
    /*
     在开始的设置openGL 窗口的时候，我们指定要一个双缓冲区的渲染环境。
     这就意味着将在后台缓冲区进行渲染，渲染结束后交换给前台。
     这种方式可以防止观察者看到可能伴随着动画帧与动画帧之间的闪烁的渲染过程。
     缓冲区交换平台将以平台特定的方式进行。
     */
    glutSwapBuffers();
    
   
    
}

/*
 自定义函数
 触发条件：在main函数中主动调用
 处理业务：1、设置背景颜色 2、初始化着色器 3、设置顶点数据 4、利用GLBatch将数据传递到着色器
 */
void setupRC()
{
    
    //1、设置背景颜色
    glClearColor(0.98f, 0.4f, 0.7f, 1);
    
    //2、初始化渲染管理器
    shaderManager.InitializeStockShaders();
    
    //3、指定三角形的顶点坐标
    GLfloat vVerts[] = {
        -0.5f,0.0f,0.0f,
        0.5f,0.0f,0.0f,
        0.0f,0.5f,0.0f,
    };
    
    //4、利用GLBatch三角形批次类，将数据传递到着色器
    triangleBatch.Begin(GL_TRIANGLES, 3);
    triangleBatch.CopyVertexData3f(vVerts);
    triangleBatch.End();
    
}



//程序入口
int main(int argc,char *argv[])
{
    //准备工作（基本上都一样）
    //1、初始化glut库
    glutInit(&argc, argv);
    //2、初始化双缓冲区窗口
    /*
    依次是：双缓冲窗口、RGBA颜色模式、深度测试、模板缓冲区
    GLUT_DOUBLE`：双缓存窗口，是指绘图命令实际上是离屏缓存区执行的，然后迅速转换成窗口视图，这种方式，经常用来生成动画效果；
    GLUT_DEPTH`：标志将一个深度缓存区分配为显示的一部分，因此我们能够执行深度测试；
    GLUT_STENCIL`：确保我们也会有一个可用的模板缓存区。
    */
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    //3、设置窗口大小
    glutInitWindowSize(1000, 800);
    //4、设置窗口标题
    glutCreateWindow("Triangle");
    //5、注册重塑函数
    glutReshapeFunc(changeSize);
    //6、注册显示渲染函数
    glutDisplayFunc(RenderScene);
    //7、初始化GLEW库，确保OpenGL的API对程序完全可用。在做渲染之前，要检查确认驱动程序的初始化过程中没有任何问题
    GLenum status = glewInit();
    if (GLEW_OK != status) {
        printf("GLEW Error:%s\n",glewGetErrorString(status));
        return 1;
    }
    
    /*
     GLUT 内部运行一个本地消息循环，拦截适当的消息。然后调用我们不同时间注册的回调函数。我们一共注册2个回调函数：
     1）为窗口改变大小而设置的一个回调函数---glutReshapeFunc
     2）包含OpenGL 渲染的回调函数---glutDisplayFunc
     */
     
    //1、设置我们的渲染环境
    setupRC();
    //2、类似于runloop运行循环
    glutMainLoop();
 
    return  0;
    
}


