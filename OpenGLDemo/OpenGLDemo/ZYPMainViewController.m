//
//  ZYPMainViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/20.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPMainViewController.h"

@interface ZYPMainViewController ()

@end

@implementation ZYPMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"%f",self.timeSinceFirstResume);
}
- (void)update{
    NSLog(@"%f",self.timeSinceFirstResume);
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
