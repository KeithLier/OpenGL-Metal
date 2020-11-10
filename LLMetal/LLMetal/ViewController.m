//
//  ViewController.m
//  LLMetal
//
//  Created by keith on 2020/11/6.
//

#import "ViewController.h"
#import "CustomRender.h"
#import "YRender.h"

@interface ViewController ()

@property (strong, nonatomic) CustomRender *render;
@property (strong, nonatomic) YRender *YRender;

@property (strong, nonatomic) MTKView *mtkView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mtkView];
    // 创建默认的device
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    if (!self.mtkView.device) {
        return;
    }
    
    // 渲染背景色
//    self.render = [[CustomRender alloc] initWithMetalKitView:self.mtkView];
//    if (!self.render) {
//        return;
//    }
//    self.mtkView.delegate = self.render;
    
    // 加载三脚形
    self.YRender = [[YRender alloc] initWithMetalKitView:self.mtkView];
    if (!self.YRender) {
        return;
    }
    self.mtkView.delegate = self.YRender;
    [self.YRender mtkView:self.mtkView drawableSizeWillChange:self.mtkView.drawableSize];
    
    self.mtkView.preferredFramesPerSecond = 60;
}


@end
