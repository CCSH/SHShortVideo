//
//  SHShortVideoViewController.m
//  SHShortVideoExmaple
//
//  Created by CSH on 2018/8/29.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "SHShortVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SHShortAVPlayer.h"
#import "SHProgressView.h"
#import "Masonry.h"

//弱引用
#define WeakSelf typeof(self) __weak weakSelf = self;

#define kSHDevice_Width  [[UIScreen mainScreen] bounds].size.width  //主屏幕的宽度
#define kSHDevice_Height [[UIScreen mainScreen] bounds].size.height //主屏幕的高度

//是否是 iPhoneX
#define  kSH_iPhoneX (kSHDevice_Width == 375.f && kSHDevice_Height == 812.f ? YES : NO)
//底部高度
#define  kSH_SafeBottom (kSH_iPhoneX ? 34.f : 0.f)
//状态栏高度
#define  kSH_StatusBarHeight  ([UIApplication sharedApplication].statusBarFrame.size.height)

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface SHShortVideoViewController ()<AVCaptureFileOutputRecordingDelegate>

//背景
@property (nonatomic, strong) UIImageView *bgView;
//摄像头切换
@property (nonatomic, strong) UIButton *cameraBtn;
//返回
@property (nonatomic, strong) UIButton *backBtn;
//确定
@property (nonatomic, strong) UIButton *sureBtn;
//取消
@property (nonatomic, strong) UIButton *cancelBtn;
//轻触拍照，按住摄像
@property (nonatomic, strong) UILabel *tipLab;
//聚焦
@property (nonatomic, strong) UIImageView *focusImage;
//拍摄
@property (nonatomic, strong) UIImageView *takeImage;
//进度
@property (nonatomic, strong) SHProgressView *progressView;
//视频预览
@property (strong, nonatomic) SHShortAVPlayer *player;

//记录状态栏状态
@property (nonatomic, assign) BOOL isStatusHidden;
//记录录制的时间 默认最大60秒
@property (nonatomic, assign) NSInteger seconds;
//是否是摄像 YES 代表是录制  NO 表示拍照
@property (nonatomic, assign) BOOL isVideo;

//缓存视频的路径
@property (nonatomic, strong) NSString *tempPath;

//视频输出流
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutput;
//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
//负责输入和输出设备之间的数据传递
@property (nonatomic) AVCaptureSession *session;
//图像预览层，实时显示捕获的图像
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

//后台任务标识
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, assign) UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier;

@end

@implementation SHShortVideoViewController

//时间大于这个就是视频，否则为拍照
#define TimeMax 1

#pragma mark - 懒加载
#pragma mark 背景
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIImageView alloc]init];
        _bgView.userInteractionEnabled = YES;
        [self.view addSubview:_bgView];
    }
    return _bgView;
}

#pragma mark 摄像头切换
- (UIButton *)cameraBtn{
    if (!_cameraBtn) {
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraBtn setBackgroundImage:[self getImageWithName:@"video_camera"] forState:UIControlStateNormal];
        [_cameraBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _cameraBtn.tag = 1;
        [self.view addSubview:_cameraBtn];
    }
    return _cameraBtn;
}

#pragma mark 返回
- (UIButton *)backBtn{
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] init];
        [_backBtn setImage:[self getImageWithName:@"video_back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _backBtn.tag = 2;
        [self.view addSubview:_backBtn];
    }
    return _backBtn;
}

#pragma mark 确认
- (UIButton *)sureBtn{
    if (!_sureBtn) {
        _sureBtn = [[UIButton alloc] init];
        [_sureBtn setImage:[self getImageWithName:@"video_confirm"] forState:UIControlStateNormal];
        [_sureBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _sureBtn.tag = 3;
        [self.view addSubview:_sureBtn];
    }
    return _sureBtn;
}

#pragma mark 取消
- (UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] init];
        [_cancelBtn setImage:[self getImageWithName:@"video_cancel"] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn.tag = 4;
        [self.view addSubview:_cancelBtn];
    }
    return _cancelBtn;
}

#pragma mark 提示
- (UILabel *)tipLab{
    if (!_tipLab) {
        _tipLab = [[UILabel alloc] init];
        _tipLab.font = [UIFont systemFontOfSize:14];
        _tipLab.textColor = [UIColor whiteColor];
        _tipLab.textAlignment = NSTextAlignmentCenter;
        _tipLab.text = @"轻触拍照，按住摄像";
        [self.view addSubview:_tipLab];
    }
    return _tipLab;
}

#pragma mark 聚焦
- (UIImageView *)focusImage{
    if (!_focusImage) {
        _focusImage = [[UIImageView alloc] initWithImage:[self getImageWithName:@"video_focusing"]];
        [self.view addSubview:_focusImage];
    }
    return _focusImage;
}

#pragma mark 录制
- (UIImageView *)takeImage{
    if (!_takeImage) {
        _takeImage = [[UIImageView alloc] init];
        _takeImage.userInteractionEnabled = YES;
        UILongPressGestureRecognizer *longGest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestAction:)];
        longGest.minimumPressDuration = 0;
        [_takeImage addGestureRecognizer:longGest];
        [self.view addSubview:_takeImage];
    }
    return _takeImage;
}

#pragma mark 进度
- (SHProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[SHProgressView alloc] init];
        _progressView.layer.cornerRadius = 60;
        _progressView.backgroundColor = [UIColor colorWithRed:174/255.0 green:178/255.0 blue:172/255.0 alpha:1];
        _progressView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_progressView];
    }
    return _progressView;
}

#pragma mark 视频预览
- (SHShortAVPlayer *)player{
    if (!_player) {
        _player = [[SHShortAVPlayer alloc]init];
        _player.frame = CGRectMake(0, 0, CGRectGetWidth(self.bgView.frame), CGRectGetHeight(self.bgView.frame));
        _player.videoUrl = [NSURL fileURLWithPath:self.tempPath];
        _player.hidden = YES;
        [self.bgView addSubview:_player];
    }
    return _player;
}

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    self.tempPath = [NSTemporaryDirectory() stringByAppendingString:@"video.mp4"];
    
    //时间不存在则默认 60
    if (!self.maxSeconds) {
        self.maxSeconds = 60;
    }
    
    //配置UI
    [self configUI];
    //隐藏提示文字
    [self performSelector:@selector(hiddenTip) withObject:nil afterDelay:3];
}

#pragma mark - 布局
#pragma mark 配置UI
- (void)configUI{
    
    WeakSelf;
    //背景
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(0);
        make.top.mas_equalTo((kSH_iPhoneX?kSH_StatusBarHeight:0));
        make.bottom.mas_equalTo(-kSH_SafeBottom);
    }];
    
    //摄像头切换
    [self.cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.trailing.mas_equalTo(-15);
        make.top.mas_equalTo(23 + (kSH_iPhoneX?kSH_StatusBarHeight:0));
    }];
    
    //进度
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(120);
        make.bottom.mas_equalTo(-28 - kSH_SafeBottom);
        make.centerX.equalTo(weakSelf.view.mas_centerX);
    }];
    
    //确认
    [self.sureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        make.centerY.equalTo(weakSelf.progressView.mas_centerY);
        make.width.height.mas_equalTo(67);
    }];
    
    //取消
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        make.centerY.equalTo(weakSelf.progressView.mas_centerY);
        make.width.height.mas_equalTo(67);
    }];
    
    //录制
    [self.takeImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        make.centerY.equalTo(weakSelf.progressView.mas_centerY);
        make.width.height.mas_equalTo(67);
    }];
    
    //返回
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.centerY.equalTo(weakSelf.progressView.mas_centerY);
        make.centerX.mas_equalTo(-weakSelf.view.center.x/2);
    }];
    
    //提示
    [self.tipLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(0);
        make.height.mas_equalTo(20);
        make.bottom.mas_equalTo(-150 - kSH_SafeBottom);
    }];
    
    //聚焦
    [self.focusImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(60);
    }];
    
    [self.view bringSubviewToFront:self.progressView];
    self.focusImage.alpha = 0;
    
    self.sureBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.progressView.hidden = YES;
    
    self.cameraBtn.hidden = NO;
    self.backBtn.hidden = NO;
    self.takeImage.hidden= NO;
    self.takeImage.image = [self getImageWithName:@"video_take"];
}

#pragma mark 重置界面布局
- (void)resetlayout{
    
    if (self.isVideo) {
        self.isVideo = NO;
        [self.player stopPlayer];
        self.player.hidden = YES;
    }else{
        self.bgView.image = nil;
    }
    
    WeakSelf;
    [self.sureBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
    }];
    
    [self.cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        
    }];
    
    self.takeImage.image = [self getImageWithName:@"video_take"];
    [self.takeImage mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        make.bottom.mas_equalTo(-56 - kSH_SafeBottom);
        make.width.height.mas_equalTo(67);
    }];
    
    self.cancelBtn.hidden = YES;
    self.sureBtn.hidden = YES;
    
    self.takeImage.hidden = NO;
    self.cameraBtn.hidden = NO;
    self.backBtn.hidden = NO;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished) {
        [self.session startRunning];
    }];
}

#pragma mark 录制结束界面布局
- (void)stoplayout{
    
    self.takeImage.hidden = YES;
    self.cameraBtn.hidden = YES;
    self.backBtn.hidden = YES;
    
    self.sureBtn.hidden = NO;
    self.cancelBtn.hidden = NO;
    
    if (self.isVideo) {
        [self.progressView clearProgress];
    }
    
    WeakSelf;
    CGFloat centerX = -kSHDevice_Width/4;
    [self.sureBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(weakSelf.progressView.mas_centerX).offset(centerX);
    }];
    
    [self.cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(weakSelf.progressView.mas_centerX).offset(-centerX);
    }];
    
    self.takeImage.image = [self getImageWithName:@"video_take"];
    [self.takeImage mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.progressView.mas_centerX);
        make.bottom.mas_equalTo(-56 - kSH_SafeBottom);
        make.width.height.mas_equalTo(67);
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished) {
        [self.session stopRunning];
    }];
}

#pragma mark - 私有方法
#pragma mark 自定义相机
- (void)customCamera{
    
    //初始化会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc] init];
    //设置分辨率 (设备支持的最高分辨率)
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    //取得后置摄像头
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    //初始化输入设备
    NSError *error;
    if (captureDevice) {
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    }
    
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //添加音频
    error = nil;
    AVCaptureDeviceInput *audioCaptureDeviceInput = nil;
    
    if (audioCaptureDevice){
        audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    }
    
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //视频输出
    self.captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    //将输入设备添加到会话
    if ([self.session canAddInput:self.captureDeviceInput]) {
        
        if (self.captureDeviceInput){
            [self.session addInput:self.captureDeviceInput];
        }
        
        if (audioCaptureDeviceInput){
            
            [self.session addInput:audioCaptureDeviceInput];
        }
        
        //设置视频防抖
        AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
        
    }else{
        //没处理成功按钮不能点击
        self.takeImage.userInteractionEnabled = NO;
    }
    
    //将输出设备添加到会话 (刚开始 是照片为输出对象)
    if (self.captureMovieFileOutput && [self.session canAddOutput:self.captureMovieFileOutput]) {
        
        [self.session addOutput:self.captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;
    //填充模式
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.bgView.layer addSublayer:self.previewLayer];
    
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    
    //开始捕捉内容
    [self.session startRunning];
    
    //添加聚焦点击
    UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusAction:)];
    [self.bgView addGestureRecognizer:gest];
}

#pragma mark 处理视频(压缩、分辨率)
- (void)dealVideoWithPath:(NSString *)path{
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // 获取文件资源
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
    // 导出资源属性
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    // 是否包含中分辨率，如果是低分辨率AVAssetExportPresetLowQuality则不清晰
    if ([presets containsObject:AVAssetExportPresetMediumQuality]) {
        
        //重定义资源属性（画质设置成中等）
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        //压缩后的文件路径
        NSString *dealPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"video.mp4"];
        
        //存在的话就删除
        if ([[NSFileManager defaultManager] fileExistsAtPath:dealPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:dealPath error:nil];
        }

        //导出路径
        exportSession.outputURL = [NSURL fileURLWithPath:dealPath];
        //导出类型
        exportSession.outputFileType = AVFileTypeMPEG4;
        //是否对网络进行优化
        exportSession.shouldOptimizeForNetworkUse = YES;
      
        WeakSelf;
        //导出
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed://失败
                {
                    NSLog(@"failed, error:%@.", exportSession.error);
                }
                    break;
                case AVAssetExportSessionStatusCancelled://转换中
                    break;
                case AVAssetExportSessionStatusCompleted://完成
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSLog(@"\n原始文件大小：%f M\n压缩后视频大小：%f M",[weakSelf getVideoSizeWithPath:weakSelf.tempPath],[weakSelf getVideoSizeWithPath:dealPath]);
                        //回调
                        if (weakSelf.finishBlock) {
                            weakSelf.finishBlock(dealPath);
                        }
                        //返回
                        [weakSelf btnAction:weakSelf.backBtn];
                    });
                }
                    break;
                default:
                    break;
            }
        }];
    }
}

#pragma mark 视频路径
- (NSString *)getVideoPath{
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    return [path stringByAppendingPathComponent:@"video.mp4"];
}

#pragma mark 设置聚焦光标位置
- (void)setFocusCursorWithPoint:(CGPoint)point{
    
    if (!self.focusImage.alpha) {
        
        self.focusImage.alpha = 1;
        self.focusImage.center = point;
        self.focusImage.transform = CGAffineTransformMakeScale(1.5, 1.5);
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.focusImage.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
            self.focusImage.alpha = 0;
        }];
    }
}

#pragma mark 取得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark 改变设备属性的统一操作方法
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        //自动白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        //自动根据环境条件开启闪光灯
        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [captureDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark 设置聚焦点
- (void)setFocus{
    
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
    }];
}

#pragma mark 获取Bundle路径
- (UIImage *)getImageWithName:(NSString *)name{
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SHShortVideo" ofType:@"bundle"];
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@@2x",path,name];
    return [UIImage imageWithContentsOfFile:imagePath];
}

#pragma mark 获取视频size
- (CGFloat)getVideoSizeWithPath:(NSString *)path{
    
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [dic fileSize]/1024.0/1024.0;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
#pragma mark 开始录制
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    
    //延迟执行
    [self performSelector:@selector(startVideoWithUrl:) withObject:fileURL afterDelay:0.5];
}

#pragma mark 录制完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    [self stopVideoWithUrl:outputFileURL];
}

#pragma mark 开始录制处理
- (void)startVideoWithUrl:(NSURL *)url{
    
    if ([self.captureMovieFileOutput isRecording]) {
        
        self.seconds--;
        
        if (self.seconds > 0) {
            
            //大于规定时间
            if (self.maxSeconds - self.seconds >= TimeMax && !self.isVideo) {
                //长按时间超过TimeMax 表示是视频录制
                self.isVideo = YES;
                //设置进度
                self.progressView.timeMax = self.seconds;
                
                //控制控件
                if (self.backBtn.hidden == NO) {
                    self.backBtn.hidden = YES;
                    
                    //更新录制按钮
                    self.takeImage.image = [self getImageWithName:@"video_takemax"];
                    [self.takeImage mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.bottom.mas_equalTo(-28 - kSH_SafeBottom);
                        make.width.height.mas_equalTo(120);
                    }];
                }
            }
            [self performSelector:@selector(startVideoWithUrl:) withObject:url afterDelay:1.0];
        } else {
            
            if ([self.captureMovieFileOutput isRecording]) {
                [self.captureMovieFileOutput stopRecording];
            }
        }
    }
}

#pragma mark 结束录制处理
- (void)stopVideoWithUrl:(NSURL *)url{
    //结束界面布局
    [self stoplayout];
    
    self.lastBackgroundTaskIdentifier = self.backgroundTaskIdentifier;
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    [self.session stopRunning];
    
    if (self.isVideo) {//视频
        
        if (url) {
            self.player.hidden = NO;
            [self.player startPlayer];
        }
    }else{//照片
        
        AVURLAsset *urlSet = [AVURLAsset assetWithURL:url];
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
        //截图的时候调整到正确的方向
        imageGenerator.appliesPreferredTrackTransform = YES;
        NSError *error;
        //缩略图创建时间 CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要获取某一秒的第几帧可以使用CMTimeMake方法)
        CMTime time = CMTimeMake(0,30);
        //缩略图实际生成的时间
        CMTime actucalTime;
        CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
        if (error) {
            NSLog(@"截取视频图片失败:%@",error.localizedDescription);
        }
        
        CMTimeShow(actucalTime);
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        
        self.bgView.image = image;
    }
}

#pragma mark - 事件方法
#pragma mark 按钮点击
- (void)btnAction:(UIButton *)btn{
    switch (btn.tag) {
        case 1://摄像头切换
        {
            //切换摄像头
            [self cameraSwitching];
        }
            break;
        case 2://返回
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        case 3://确定
        {
            //完成
            [self finishVideo];
        }
            break;
        case 4://取消
        {
            //重新配置UI
            [self resetlayout];
        }
            break;
        default:
            break;
    }
}

#pragma mark 录制点击
- (void)gestAction:(UIGestureRecognizer *)gest{
    
    switch (gest.state) {
        case UIGestureRecognizerStateBegan://开始
        {
            [self startVideo];
        }
            break;
        case UIGestureRecognizerStateEnded://结束
        {
            if (self.isVideo) {
                [self stopVideo];
            } else {
                [self performSelector:@selector(stopVideo) withObject:nil afterDelay:0.3];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark 聚焦点击
- (void)focusAction:(UITapGestureRecognizer *)gest{
    
    if ([self.session isRunning]) {
        //对焦
        CGPoint point = [gest locationInView:self.bgView];
        [self setFocusCursorWithPoint:point];
        //设置焦点
        [self setFocus];
    }
}

#pragma mark - 私有方法
#pragma mark 隐藏提示文字
- (void)hiddenTip{
    
    [self.tipLab removeFromSuperview];
}

#pragma mark 摄像头切换
- (void)cameraSwitching{
    
    AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    
    //前
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront){
        //后
        toChangePosition = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.session beginConfiguration];
    //移除原有输入对象
    [self.session removeInput:self.captureDeviceInput];
    
    //添加新的输入对象
    if ([self.session canAddInput:toChangeDeviceInput]) {
        [self.session addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    //提交会话配置
    [self.session commitConfiguration];
}

#pragma mark - 录制操作
#pragma mark 开始录制
- (void)startVideo{
    
    self.seconds = self.maxSeconds;
    
    //根据设备输出获得连接
    AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeAudio];
    
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) {
        //如果支持多任务则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        
        //预览图层和视频方向保持一致
        connection.videoOrientation = [self.previewLayer connection].videoOrientation;
        NSURL *fileUrl = [NSURL fileURLWithPath:self.tempPath];
        
        //删除上次的临时文件
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.tempPath]) {
            [[NSFileManager defaultManager] removeItemAtURL:fileUrl error:nil];
        }
        
        //开始录制
        [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    } else {
        //结束录制
        [self.captureMovieFileOutput stopRecording];
    }
}

#pragma mark 结束录制
- (void)stopVideo{
    
    [self.captureMovieFileOutput stopRecording];
}

#pragma mark 完成录制
- (void)finishVideo{
    
    WeakSelf;
    
    if (self.isVideo) {
        
        [self.player stopPlayer];
        self.player.hidden = YES;
        
        if (self.isSave) {//保存到系统
            
            [[ALAssetsLibrary new] writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:self.tempPath] completionBlock:^(NSURL *assetURL, NSError *error) {
                
                if (error) {
                    NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
                }else{
                    //处理视频
                    [weakSelf dealVideoWithPath:weakSelf.tempPath];
                }
            }];
        }else{
            //处理视频
            [self dealVideoWithPath:self.tempPath];
        }
        
    } else {
        
        if (self.isSave) {//保存到系统
            //保存照片
            [[ALAssetsLibrary new] writeImageToSavedPhotosAlbum:[self.bgView.image CGImage] orientation:(ALAssetOrientation)self.bgView.image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"保存图片到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
                }else{
                    //回调
                    if (weakSelf.finishBlock) {
                        weakSelf.finishBlock(weakSelf.bgView.image);
                    }
                    //返回
                    [weakSelf btnAction:weakSelf.backBtn];
                }
            }];
        }else{
            //回调
            if (self.finishBlock) {
                self.finishBlock(self.bgView.image);
            }
            //返回
            [self btnAction:self.backBtn];
        }
    }
}

#pragma mark - 界面周期
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //更改状态栏
    self.isStatusHidden = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    //自定义相机
    [self customCamera];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //对焦
    self.focusImage.alpha = 0;
    [self setFocusCursorWithPoint:self.bgView.center];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    //停止捕捉内容
    [self.session stopRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //还原状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:self.isStatusHidden];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
