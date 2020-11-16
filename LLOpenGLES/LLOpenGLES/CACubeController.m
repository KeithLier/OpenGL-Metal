//
//  CASuqareController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/16.
//

#import "CACubeController.h"

@interface CACubeController ()

@property (assign, nonatomic) NSInteger angle;
@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation CACubeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self createCube];
    [self addCADisplayLink];
}

- (void)createCube {
    // 1.设置self.view的layer图层
    // 这里把layer层通过放射变换，相当于换了一个角度，为了让我们更加清楚的看到一个正方体，而不是一个四边形
    CATransform3D perspective = CATransform3DIdentity;
    // 核心动画设置透视投影
    perspective.m34 = -1.0 / 500.0;
    // 围绕x、y轴分别旋转45度
    perspective = CATransform3DRotate(perspective, -M_PI/4, 1, 0, 0);
    perspective = CATransform3DRotate(perspective, -M_PI/4, 0, 1, 0);
    self.view.layer.sublayerTransform = perspective;
    
    // 2.创建6个Label，每个Label不同方向旋转，组成一个正方体
    NSArray *array = @[@"1",@"2",@"3",@"4",@"5",@"6"];
    for (int i = 0; i < array.count; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        label.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
        label.backgroundColor = [UIColor colorWithRed:arc4random() % 255 / 255.0 green:arc4random() % 255 / 255.0 blue:arc4random() % 255 / 255.0 alpha:1];
        label.text = array[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:40];
        label.textColor = [UIColor whiteColor];
        [self.view addSubview:label];
        
        CATransform3D transform;
        if (i == 0) {
            transform = CATransform3DMakeTranslation(0, 0, 100);
        } else if (i == 1) {
            transform = CATransform3DMakeTranslation(100, 0, 0);
            transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
        } else if (i == 2) {
            transform = CATransform3DMakeTranslation(0, -100, 0);
            transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
        } else if (i == 3) {
            transform = CATransform3DMakeTranslation(0, 100, 0);
            transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
        } else if (i == 4) {
            transform = CATransform3DMakeTranslation(-100, 0, 0);
            transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
        } else {
            transform = CATransform3DMakeTranslation(0, 0, -100);
            transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
        }
        label.layer.transform = transform;
    }
    
}

- (void)addCADisplayLink {
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)update {
    //1、计算旋转角度
    self.angle = (self.angle + 5) % 360;
    //2、转成弧度
    float deg = self.angle * (M_PI / 180);
    //3、设置旋转矩阵
    CATransform3D temp = CATransform3DIdentity;
    //围绕（0.3，1，0.7）进行旋转
    temp = CATransform3DRotate(temp, deg, 0.3, 1, 0.7);
    self.view.layer.sublayerTransform = temp;
}

@end
