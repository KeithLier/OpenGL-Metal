//
//  GLSLImageController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/17.
//

// 1.设置图层CAEAGLLayer
// 2.设置上下文EAGLContext
// 3.清空缓冲区
// 4.设置renderBuffer
// 5.设置frameBuffer
// 6.开始绘制

#import "GLSLImageController.h"
#import "GLSLView.h"

@interface GLSLImageController ()

@end

@implementation GLSLImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    GLSLView *glslView = [[GLSLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glslView];
}


@end
