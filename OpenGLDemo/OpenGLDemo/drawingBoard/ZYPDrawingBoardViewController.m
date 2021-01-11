//
//  ZYPDrawingBoardViewController.m
//  OpenGLDemo
//
//  Created by imac on 2020/12/7.
//  Copyright © 2020 imac. All rights reserved.
//

#import "ZYPDrawingBoardViewController.h"
#import "ZYPDrawingBoardView.h"
#import "ZYPDrawingBoardSoundEffect.h"

//亮度
#define kBrightness             1.0
//饱和度
#define kSaturation             0.45
//调色板高度
#define kPaletteHeight            30
//调色板大小
#define kPaletteSize            5
//最小擦除区间
#define kMinEraseInterval        0.5

//填充率
#define kLeftMargin                10.0
#define kTopMargin                10.0
#define kRightMargin            10.0

@interface ZYPDrawingBoardViewController ()
{
    //清除屏幕声音
    ZYPDrawingBoardSoundEffect            *erasingSound;
    //选择颜色声音
    ZYPDrawingBoardSoundEffect            *selectSound;
    
    CFTimeInterval        lastTime;
}

@end

@implementation ZYPDrawingBoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //1.UI实现
    self.navigationItem.title = @"画板";
    [self setUpUI];
}

- (void)setUpUI
{
    
    UIButton*clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake(0, 0, 50, 44);
    [clearBtn setTitle:@"清屏" forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:clearBtn];
    
    //1.数组存储颜色选择的图片
    UIImage *redImag = [[UIImage imageNamed:@"Red"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *yellowImag = [[UIImage imageNamed:@"Yellow"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *greenImag =[[UIImage imageNamed:@"Green"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *blueImag = [[UIImage imageNamed:@"Blue"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    NSArray *selectColorImagArr = @[redImag,yellowImag,greenImag,blueImag];
    
    //2.创建一个分段控件，让用户可以选择画笔颜色
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:selectColorImagArr];
    
    //3.计算一个矩形的位置，它可以正确设置为用作画笔调色板的分段控件
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
    segmentedControl.frame = frame;
    
    //4.为了segmentedControl添加按钮事件--改变画笔颜色
    [segmentedControl addTarget:self action:@selector(changBrushColor:) forControlEvents:UIControlEventValueChanged];
    
    
    //5.设置tintColor & 默认选择
    segmentedControl.tintColor = [UIColor darkGrayColor];
    segmentedControl.selectedSegmentIndex = 2;
    
    [self.view addSubview:segmentedControl];
    
    //6.定义起始颜色
    //创建并返回一个颜色对象使用指定的不透明的HSB颜色空间的分量值
    /*
     参数列表：
     Hue:色调 = 选择的index/颜色选择总数
     saturation:饱和度
     brightness:亮度
     */
    CGColorRef color = [UIColor colorWithHue:(CGFloat)2.0/(CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;
    
    //根据颜色值，返回颜色相关的颜色组件
    const CGFloat *components = CGColorGetComponents(color);
    
    //根据OpenGL视图设置画笔颜色
    [(ZYPDrawingBoardView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
    
    //加载声音--选择颜色声音、清空屏幕颜色
    NSString *erasePath = [[NSBundle mainBundle]pathForResource:@"Erase" ofType:@"caf"];
    NSString *selectPath = [[NSBundle mainBundle]pathForResource:@"Select" ofType:@"caf"];
    
    //根据路径加载声音
    erasingSound = [[ZYPDrawingBoardSoundEffect alloc]initWithContentsOfFile:erasePath];
    selectSound = [[ZYPDrawingBoardSoundEffect alloc]initWithContentsOfFile:selectPath];
    
    
}
- (void)clearAction{
    [(ZYPDrawingBoardView *)self.view erase];
}

//改变画笔颜色
-(void)changBrushColor:(id)sender
{
    NSLog(@"Change Color!");
    
    //1.播放声音
    [selectSound play];
    
    // 定义新的画笔颜色 创建并返回一个颜色对象使用指定的不透明的HSB颜色空间的分量值
    CGColorRef color = [UIColor colorWithHue:(CGFloat)[sender selectedSegmentIndex] / (CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;
    
    //返回颜色的组件，红、绿、蓝、alpha颜色值
    const CGFloat *components = CGColorGetComponents(color);
    
    // 根据OpenGL视图设置画笔颜色
    [(ZYPDrawingBoardView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
    
}

- (IBAction)earse:(id)sender {
    
    //清理屏幕上的图像
    [self eraseView];
    
}

//播放抹去的声音并抹去视图
- (void)eraseView
{
    /*
     参考课件！
     NSDate、CFAbsoluteTimeGetCurrent、CACurrentMedaiTime的区别？
     */
    //防止一直不停的点击清除屏幕！
    //当前设备时间 > 上一次点击时间 + 间隔时间
    if(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval) {
        
        NSLog(@"清除屏幕！");
        
        //播放系统声音
        [erasingSound play];
        
        //清理屏幕
        [(ZYPDrawingBoardView *)self.view erase];
        
        //保存这次时间到 lastTime
        lastTime = CFAbsoluteTimeGetCurrent();
    }
}



@end
