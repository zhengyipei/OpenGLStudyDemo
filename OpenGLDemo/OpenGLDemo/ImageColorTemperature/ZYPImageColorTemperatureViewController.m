//
//  ZYPImageColorTemperatureViewController.m
//  OpenGLDemo
//
//  Created by imac on 2021/1/21.
//  Copyright © 2021 imac. All rights reserved.
//

#import "ZYPImageColorTemperatureViewController.h"
#import "ZYPContainerView.h"

@interface ZYPImageColorTemperatureViewController ()
@property  (nonatomic,strong) IBOutlet ZYPContainerView *glContainerView;
@end

@implementation ZYPImageColorTemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.glContainerView.image = [UIImage imageNamed:@"Lena"];
}
- (IBAction)saturationAction:(UISlider *)sender {
    self.glContainerView.saturationValue = sender.value;
}
- (IBAction)temperatureAction:(UISlider *)sender {
    self.glContainerView.colorTempValue = sender.value;
}
@end
