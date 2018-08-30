//
//  SHProgressView.m
//  SHShortVideoExmaple
//
//  Created by CSH on 2018/8/29.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "SHProgressView.h"

@interface SHProgressView ()

//进度
@property (nonatomic, assign) CGFloat progressValue;
//当前时间
@property (nonatomic, assign) CGFloat currentTime;

@end

@implementation SHProgressView

- (void)drawRect:(CGRect)rect {
    
    CGFloat line_w = 5;
    //开始绘制
    //获取上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //设置圆心位置
    CGPoint center = CGPointMake(self.frame.size.width/2.0, self.frame.size.width/2.0);
    //设置半径
    CGFloat radius = self.frame.size.width/2.0-(line_w/2);
    //圆起点位置
    CGFloat startA = - M_PI_2;
    //圆终点位置
    CGFloat endA = -M_PI_2 + M_PI * 2 * _progressValue;
    
    //设置路径
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    
    //设置线条宽度
    CGContextSetLineWidth(ctx, line_w);
    //设置描边颜色
    [[UIColor colorWithRed:88/255.0 green:180/255.0 blue:97/255.0 alpha:1] setStroke];
    //把路径添加到上下文
    CGContextAddPath(ctx, path.CGPath);
    //渲染
    CGContextStrokePath(ctx);
}

- (void)setTimeMax:(NSInteger)timeMax {
    _timeMax = timeMax;
    self.currentTime = 0;
    self.progressValue = 0;
    [self setNeedsDisplay];
    self.hidden = NO;
    [self performSelector:@selector(startProgress) withObject:nil afterDelay:0.1];
}

- (void)clearProgress {
    _currentTime = _timeMax;
    self.hidden = YES;
}

- (void)startProgress {
    
    _currentTime += 0.1;
    if (_timeMax > _currentTime) {
        _progressValue = _currentTime/_timeMax;
        [self setNeedsDisplay];
        [self performSelector:@selector(startProgress) withObject:nil afterDelay:0.1];
    }
    
    if (_timeMax <= _currentTime) {
        [self clearProgress];
        
    }
}

@end
