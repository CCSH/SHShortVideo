//
//  SHProgressView.h
//  SHShortVideoExmaple
//
//  Created by CSH on 2018/8/29.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 进度
 */
@interface SHProgressView : UIView

@property (nonatomic, assign) NSInteger timeMax;

- (void)clearProgress;

@end
