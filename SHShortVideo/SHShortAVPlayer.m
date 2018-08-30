//
//  SHShortAVPlayer.m
//  SHShortVideoExmaple
//
//  Created by CSH on 2018/8/29.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "SHShortAVPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface SHShortAVPlayer ()

//播放器对象
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation SHShortAVPlayer

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopPlayer];
    self.player = nil;
}

#pragma mark 播放完成
- (void)playbackFinished {
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

#pragma mark - 公共方法
#pragma mark 开始播放
- (void)startPlayer{
    
    //初始化
    self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:self.videoUrl]];
    
    //创建播放器层
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    playerLayer.frame = self.frame;
    [self.layer addSublayer:playerLayer];
    
    if (self.player.rate == 0) {
        [self.player play];
    }
    
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

#pragma mark 结束播放
- (void)stopPlayer {
    if (self.player.rate == 1) {
        [self.player pause];//如果在播放状态就停止
    }
    self.player = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
