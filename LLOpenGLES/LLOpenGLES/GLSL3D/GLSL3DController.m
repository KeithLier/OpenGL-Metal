//
//  GLSL3DController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/18.
//

#import "GLSL3DController.h"
#import "GLSL3DView.h"
@interface GLSL3DController ()

@end

@implementation GLSL3DController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    GLSL3DView *glslView = [[GLSL3DView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glslView];

}


@end
