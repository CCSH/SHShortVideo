//
//  ViewController.m
//  SHShortVideoExmaple
//
//  Created by CSH on 2018/8/29.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "ViewController.h"
#import "SHShortVideoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    SHShortVideoViewController *vc = [[SHShortVideoViewController alloc]init];
    vc.maxSeconds = 10;
//    vc.isSave = YES;
    vc.finishBlock = ^(id content) {
        if ([content isKindOfClass:[NSString class]]) {
            NSLog(@"视频路径：%@",content);
        }else if ([content isKindOfClass:[UIImage class]]){
            NSLog(@"图片内容：%@",content);
        }
    };
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
