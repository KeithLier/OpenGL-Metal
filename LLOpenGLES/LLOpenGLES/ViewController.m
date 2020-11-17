//
//  ViewController.m
//  LLOpenGLES
//
//  Created by keith on 2020/11/12.
//

#import "ViewController.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *items;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.items = @[
        @{@"name":@"GLKit加载图片",@"vc":@"GLImageController"},
        @{@"name":@"GLKit绘制正方体",@"vc":@"GLCubeController"},
        @{@"name":@"CoreAnimation绘制正方体",@"vc":@"CACubeController"},
        @{@"name":@"GLSL加载图片",@"vc":@"GLSLImageController"}
    ];
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tableViewCell"];
    }
    NSDictionary *dict = self.items[indexPath.row];
    cell.textLabel.text = dict[@"name"];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = self.items[indexPath.row];
    NSString *vc = dict[@"vc"];
    UIViewController *controller = [[NSClassFromString(vc) alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
