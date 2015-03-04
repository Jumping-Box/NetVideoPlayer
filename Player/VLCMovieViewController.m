/*****************************************************************************
 * VLCMovieViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Ahmad Harb <harb.dev.leb # gmail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"
#import "VLCConstants.h"
#import "VLCFrostedGlasView.h"

#import <MobileVLCKit/MobileVLCKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "UIDevice+SpeedCategory.h"

#import "VLCThumbnailsCache.h"

#import "OBSlider.h"
#import "VLCStatusLabel.h"

#import "NSString+SupportedMedia.h"

#import <MobileVLCKit/MobileVLCKit.h>

#define INPUT_RATE_DEFAULT  1000.
#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10

#define KEY_PATH_MEDIA_PLAYER_TIME @"time"
#define KEY_PATH_MEDIA_PLAYER_REMAINING_TIME @"remainingTime"
#define DEBUG 1
#ifdef DEBUG
#define SBDebugLog(...) NSLog(__VA_ARGS__)
#else
#define SBDebugLog(...)
#endif
@interface VLCMovieViewController () <
UIGestureRecognizerDelegate,
AVAudioSessionDelegate,
VLCMediaDelegate,
VLCMediaPlayerDelegate,
UIActionSheetDelegate>
{

    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;
    
    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;
    UIActionSheet *_moreActionSheet;
    
    float _currentPlaybackRate;
    NSArray *_aspectRatios;
    NSUInteger _currentAspectRatioMask;
    
    NSTimer *_idleTimer;
    
    BOOL _shouldResumePlaying;
    BOOL _viewAppeared;
    BOOL _positionSet;
    BOOL _playerIsSetup;
    BOOL _isScrubbing;
    
    BOOL _shouldPlayNext;
    NSTimer *_shouldPlayNextTimer;
    
    BOOL _canEndPlay;
    NSTimer *_shouldEndPlay;
    
    BOOL _swipeGesturesEnabled;
    NSString * panType;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UITapGestureRecognizer *_tapRecognizer;
    
    VLCMedia *_media;
  
}

@property (nonatomic, strong) VLCMediaPlayer *mediaPlayer;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIWindow *externalWindow;

@property (nonatomic, strong) SBMediaItem *currentMediaItem;

@end

@implementation VLCMovieViewController

- (void)dealloc
{
    if (_tapRecognizer)
        [self.view removeGestureRecognizer:_tapRecognizer];
    if (_swipeRecognizerLeft)
        [self.view removeGestureRecognizer:_swipeRecognizerLeft];
    if (_swipeRecognizerRight)
        [self.view removeGestureRecognizer:_swipeRecognizerRight];
    if (_panRecognizer)
        [self.view removeGestureRecognizer:_panRecognizer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //[[SBPreference sharedPreference] removeObserver:self forKeyPath:KEY_PATH_SHOULD_AUTO_ROTATE];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//    if(nibBundleOrNil == nil) {
//        nibBundleOrNil = [PlayerFramework bundle];
//    }
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSNumber *skipLoopFilterDefaultValue;
        int deviceSpeedCategory = [[UIDevice currentDevice] speedCategory];
        if (deviceSpeedCategory < 3)
            skipLoopFilterDefaultValue = kVLCSettingSkipLoopFilterNonKey;
        else
            skipLoopFilterDefaultValue = kVLCSettingSkipLoopFilterNonRef;
        
        NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"", kVLCSettingPasscodeOnKey : @(NO), kVLCSettingContinueAudioInBackgroundKey : @(YES), kVLCSettingStretchAudio : @(NO), kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue, kVLCSettingSkipLoopFilter : skipLoopFilterDefaultValue, kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue, kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue, kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue, kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue, kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue};
        
        [defaults registerDefaults:appDefaults];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;
    
    _shouldPlayNext = YES;
    _canEndPlay = NO;
    
    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;
    
    _hueLabel.text = @"VFILTER_HUE";
    _contrastLabel.text = @"VFILTER_CONTRAST";
    _brightnessLabel.text = @"VFILTER_BRIGHTNESS";
    _saturationLabel.text = @"VFILTER_SATURATION";
    _gammaLabel.text = @"VFILTER_GAMMA";
    _playbackSpeedLabel.text = @"PLAYBACK_SPEED";
    _scrubHelpLabel.text = @"PLAYBACK_SCRUB_HELP";
    _playingExternallyTitle.text = @"PLAYING_EXTERNALLY_TITLE";
    _playingExternallyDescription.text = @"PLAYING_EXTERNALLY_DESC";
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    
    [center addObserver:self selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillEnterForeground:)
                   name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [center addObserver:self selector:@selector(statusBarDidChangeFrame:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [self addObserver:self forKeyPath:@"shouldAutoRotate" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    _movieView.userInteractionEnabled = NO;
    _movieViewContainer.userInteractionEnabled = NO;
    
    UITapGestureRecognizer *tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    tapOnVideoRecognizer.numberOfTapsRequired = 1;
    tapOnVideoRecognizer.numberOfTouchesRequired = 1;
    tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapOnVideoRecognizer];
    
    UITapGestureRecognizer *doubleTapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoDimension)];
    doubleTapOnVideoRecognizer.numberOfTapsRequired = 2;
    doubleTapOnVideoRecognizer.numberOfTouchesRequired = 1;
    doubleTapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:doubleTapOnVideoRecognizer];
    
    [tapOnVideoRecognizer requireGestureRecognizerToFail:doubleTapOnVideoRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:pinchRecognizer];
    
    _swipeGesturesEnabled = YES;
    if (_swipeGesturesEnabled) {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
        [_tapRecognizer setNumberOfTouchesRequired:2];
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
        [_panRecognizer setMinimumNumberOfTouches:1];
        [_panRecognizer setMaximumNumberOfTouches:1];
        
        _swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
        _swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        _swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
        _swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
        
        [self.view addGestureRecognizer:_swipeRecognizerLeft];
        [self.view addGestureRecognizer:_swipeRecognizerRight];
        [self.view addGestureRecognizer:_panRecognizer];
        [self.view addGestureRecognizer:_tapRecognizer];
        [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerLeft];
        [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerRight];
        
        _panRecognizer.delegate = self;
        _swipeRecognizerRight.delegate = self;
        _swipeRecognizerLeft.delegate = self;
        _tapRecognizer.delegate = self;
    }
    
    _aspectRatios = @[@"DEFAULT", @"FILL_TO_SCREEN", @"4:3", @"16:9", @"16:10", @"2.21:1"];
    
    //[self.aspectRatioButton setImage:[PlayerFramework loadImage:@"ratioIcon.png"] forState:UIControlStateNormal];
    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon.png"] forState:UIControlStateNormal];
    
    /* FIXME: there is a saner iOS 6+ API for this! */
    /* this looks a bit weird, but we need to support iOS 5 and should show the same appearance */
    void (^initVolumeSlider)(MPVolumeView *) = ^(MPVolumeView *volumeView){
        UISlider *volumeSlider = nil;
        for (id aView in volumeView.subviews){
            NSLog(@"[aView class] description=%@",[[aView class] description]);
            if ([[[aView class] description] isEqualToString:@"MPVolumeSlider"]){
                volumeSlider = (UISlider *)aView;
                NSLog(@"OK,%@",volumeView);
                break;
            }
        }
        
        if(volumeSlider) {
            UIImage *minTrackImage = [UIImage imageNamed:@"sliderMinimumTrack.png"];//[PlayerFramework loadImage:@"sliderMinimumTrack.png"];
            UIImage *maxTrackImage = [UIImage imageNamed:@"sliderMaximumTrack.png"];//[PlayerFramework loadImage:@"sliderMaximumTrack.png"];
            minTrackImage = [minTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, minTrackImage.size.width / 2.0f, 0, minTrackImage.size.width / 2.0f)];
            maxTrackImage = [maxTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, maxTrackImage.size.width / 2.0f, 0, maxTrackImage.size.width / 2.0f)];
            [volumeView setMinimumVolumeSliderImage:minTrackImage forState:UIControlStateNormal];
            [volumeView setMaximumVolumeSliderImage:maxTrackImage forState:UIControlStateNormal];
            [volumeView setMinimumVolumeSliderImage:minTrackImage forState:UIControlStateHighlighted];
            [volumeView setMaximumVolumeSliderImage:maxTrackImage forState:UIControlStateHighlighted];
            
            if(SYSTEM_RUNS_IOS7_OR_LATER) {
                //[volumeView setVolumeThumbImage:[PlayerFramework loadImage:@"modernSliderKnob.png"] forState:UIControlStateNormal];
                [volumeView setVolumeThumbImage:[UIImage imageNamed:@"modernSliderKnob.png"] forState:UIControlStateNormal];
            } else {
                //[volumeView setVolumeThumbImage:[PlayerFramework loadImage:@"volumeSliderKnob.png"] forState:UIControlStateNormal];
                [volumeView setVolumeThumbImage:[UIImage imageNamed:@"volumeSliderKnob.png"] forState:UIControlStateNormal];
            }
            [volumeSlider addTarget:self
                             action:@selector(volumeSliderAction:)
                   forControlEvents:UIControlEventValueChanged];
        }
    };
    
    initVolumeSlider(self.volumeView);
    initVolumeSlider(self.volumeViewLandscape);
    
    [self.mediaInfoButton setImage:[UIImage imageNamed:@"mediaInfo.png"] forState:UIControlStateNormal];
    [self.moreActionButton setImage:[UIImage imageNamed:@"moreAction.png"] forState:UIControlStateNormal];
    [[AVAudioSession sharedInstance] setDelegate:self];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //self.positionSlider.scrubbingSpeedChangePositions = @[@(0.), @(100.), @(200.), @(300)];
    }else{
        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            CGRect frameValue = self.positionSlider.frame;
            frameValue.origin.y = (self.navigationView.frame.size.height-20)/2 - frameValue.size.height/2+20;
            self.positionSlider.frame = frameValue;
        }
    }
    
    _playerIsSetup = NO;
    
    [self.view addSubview:self.navigationView];
    
    [self adjustScreenLockImage];
    [self adjustOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
        }
    }
    
    self.movieView.frame = self.movieViewContainer.bounds;
    [self.movieViewContainer addSubview:self.movieView];
    if([self.movieViewControllerDelegate respondsToSelector:@selector(moviePlayerWillStart:)]) {
        [self.movieViewControllerDelegate moviePlayerWillStart:self];
    }
    
    
    
    [self setControlsHidden:NO animated:YES];
    _viewAppeared = YES;

    _canEndPlay = NO;
    if (_shouldEndPlay) {
        [_shouldEndPlay invalidate];
        _shouldEndPlay = nil;
    }
//    if (_shouldEndPlay == nil) {
        _shouldEndPlay =[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(endPlaybackTimer:) userInfo:nil repeats:NO];
//    }
   
    [self playMediaAtIndex:0];
    [self _startPlayback];
}

- (void)viewWillLayoutSubviews
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGSize viewSize = self.view.frame.size;
        
        CGSize trueSize = CGSizeApplyAffineTransform(viewSize, self.view.transform);
        
        //矩阵转换后的数值可能为负数，这里取其绝对值
        trueSize = (CGSize){fabs(trueSize.width), fabs(trueSize.height)};
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [_controllerPanel removeFromSuperview];
            _controllerPanelLandscape.frame = (CGRect){CGPointMake(0, trueSize.height - _controllerPanelLandscape.frame.size.height), CGSizeMake(trueSize.width, _controllerPanelLandscape.frame.size.height)};
            [self.view addSubview:_controllerPanelLandscape];
        } else {
            [_controllerPanelLandscape removeFromSuperview];
            _controllerPanel.frame = (CGRect){CGPointMake(0, trueSize.height - _controllerPanel.frame.size.height), CGSizeMake(trueSize.width, _controllerPanel.frame.size.height)};
            [self.view addSubview:_controllerPanel];
        }
        [self adjustOrientation];
    }
}

- (BOOL)_blobCheck
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[directoryPath stringByAppendingPathComponent:@"blob.bin"]])
        return NO;
    
    NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:@"blob.bin"]];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (unsigned int u = 0; u < CC_SHA1_DIGEST_LENGTH; u++)
        [hash appendFormat:@"%02x", digest[u]];
    
    if ([hash isEqualToString:kBlobHash])
        return YES;
    else
        return NO;
}

- (void)_startPlayback
{
    if (_playerIsSetup)
        return;
    
    if (!self.currentMediaItem && !self.playlist) {
        [self _stopPlayback];
        return;
    }
    
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";
    
    VLCMedia *media;
    if (self.currentMediaItem) {
        media = [VLCMedia mediaWithURL:self.currentMediaItem.url];
    }

    
    self.positionSlider.value = 0.;
    self.remainTimeLabel.text = @"";
    self.remainTimeLabel.accessibilityLabel = @"";
    
    if (![self _isMediaSuitableForDevice]) {

    } else {
        [self _playNewMedia];
    }
    
    if (![self hasExternalDisplay]) {
        self.brightnessSlider.value = [UIScreen mainScreen].brightness * 2.;
    }
}

- (BOOL)_isMediaSuitableForDevice
{
//    if (!self.mediaItem)
//        return YES;
//    
//    NSUInteger totalNumberOfPixels = [[[self.mediaItem videoTrack] valueForKey:@"width"] doubleValue] * [[[self.mediaItem videoTrack] valueForKey:@"height"] doubleValue];
//    
//    NSInteger speedCategory = [[UIDevice currentDevice] speedCategory];
//    
//    if (speedCategory == 1) {
//        // iPhone 3GS, iPhone 4, first gen. iPad, 3rd and 4th generation iPod touch
//        return (totalNumberOfPixels < 600000); // between 480p and 720p
//    } else if (speedCategory == 2) {
//        // iPhone 4S, iPad 2 and 3, iPod 4 and 5
//        return (totalNumberOfPixels < 922000); // 720p
//    } else if (speedCategory == 3) {
//        // iPhone 5, iPad 4
//        return (totalNumberOfPixels < 2074000); // 1080p
//    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self _playNewMedia];
    else {
        [self _stopPlayback];
        [self closePlayback:nil];
    }
}

- (void)_playNewMedia
{
    //NSLog(@"_mediaPlayer=%@",_mediaPlayer);
    [_mediaPlayer addObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_TIME options:NSKeyValueObservingOptionNew context:nil];
    [_mediaPlayer addObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_REMAINING_TIME options:NSKeyValueObservingOptionNew context:nil];
    self.playbackSpeedSlider.value = [self _playbackSpeed];
    
    _currentAspectRatioMask = 0;
    _mediaPlayer.videoAspectRatio = NULL;
    
    
    [self _resetIdleTimer];
    _playerIsSetup = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self _stopPlayback];
    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];
    
    // hide filter UI for next run
    if (!_videoFiltersHidden) {
        _videoFiltersHidden = YES;
    }
    
    if (!_playbackSpeedViewHidden) {
        _playbackSpeedViewHidden = YES;
    }
}

- (void)_stopPlayback
{
    if (_mediaPlayer) {
        @try {
            [_mediaPlayer removeObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_TIME];
            [_mediaPlayer removeObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_REMAINING_TIME];
        }
        @catch (NSException *exception) {
            APLog(@"we weren't an observer yet");
        }
        
        if (_mediaPlayer.media) {
            [_mediaPlayer pause];
            [self _saveCurrentState];
            [_mediaPlayer stop];
        }
        self.mediaPlayer = nil;
    }
    self.currentMediaItem = nil;
    self.playlist = nil;
    
    _playerIsSetup = NO;
}

- (void)_saveCurrentState
{
//    if (self.mediaItem) {
//        @try {
//            MLFile *item = self.mediaItem;
//            item.lastPosition = @([_mediaPlayer position]);
//            item.lastAudioTrack = @(_mediaPlayer.currentAudioTrackIndex);
//            item.lastSubtitleTrack = @(_mediaPlayer.currentVideoSubTitleIndex);
//        }
//        @catch (NSException *exception) {
//            APLog(@"failed to save current media state - file removed?");
//        }
//    }
}

#pragma mark - remote events

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    if ([self hasExternalDisplay]) {
        [self showOnExternalDisplay];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [self.mediaPlayer play];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [self.mediaPlayer pause];
            break;
            
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self playPause];
            break;
            
        case UIEventSubtypeRemoteControlNextTrack:
            [self forward:nil];
            break;
            
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self backward:nil];
            break;
            
        case UIEventSubtypeRemoteControlStop:
            [self closePlayback:nil];
            break;
            
        default:
            break;
    }
}

#pragma mark - controls visibility

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (recognizer.velocity < 0.)
        [self closePlayback:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view)
        return NO;
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    _controlsHidden = hidden;
    CGFloat alpha = _controlsHidden? 0.0f: 1.0f;
    
    if (!_controlsHidden) {
        _controllerPanel.alpha = 0.0f;
        _controllerPanel.hidden = !_videoFiltersHidden;
        _controllerPanelLandscape.alpha = 0.0f;
        _controllerPanelLandscape.hidden = !_videoFiltersHidden;
        _videoFilterView.alpha = 0.0f;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.alpha = 0.0f;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        _navigationView.alpha = 0.0f;
        _navigationView.hidden = !_videoFiltersHidden;
    }
    
    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
        _controllerPanelLandscape.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
        _navigationView.alpha = alpha;
    };
    
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _controllerPanel.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _controllerPanelLandscape.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        _navigationView.hidden = _videoFiltersHidden ? _controlsHidden : NO;
    };
    
    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;
    
    BOOL needHideStatusBar = _viewAppeared ? _controlsHidden : NO;
    if(self.inMiniTVMode) {
        //非小电视模式下才隐藏
        needHideStatusBar = NO;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:needHideStatusBar withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
    
    _volumeView.hidden = _volumeViewLandscape.hidden = _controllerPanel.hidden;
}

- (void)toggleControlsVisible
{
    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;
    
    [self setControlsHidden:!_controlsHidden animated:YES];
}

- (void)_resetIdleTimer
{
    if (!_idleTimer)
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:4.
                                                      target:self
                                                    selector:@selector(idleTimerExceeded)
                                                    userInfo:nil
                                                     repeats:NO];
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 4.)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.]];
    }
}

- (void)idleTimerExceeded
{
    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible];
    
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;
    
    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;
    
    if (self.scrubIndicatorView.hidden == NO)
        self.scrubIndicatorView.hidden = YES;
}

- (UIResponder *)nextResponder
{
    [self _resetIdleTimer];
    return [super nextResponder];
}

#pragma mark - controls
- (void)adjustScreenLockImage
{
//    if ([[SBPreference sharedPreference].shouldAutoRotate boolValue]) {
//        UIImage *unlockImage = [PlayerFramework loadImage:@"screenUnlock.png"];
//        [self.screenLockButton setImage:unlockImage
//                               forState:UIControlStateNormal];
//        [self.screenLockButtonLandscape setImage:unlockImage forState:UIControlStateNormal];
//    } else {
//        UIImage *lockImage = [PlayerFramework loadImage:@"screenLock.png"];
//        [self.screenLockButton setImage:lockImage
//                               forState:UIControlStateNormal];
//        [self.screenLockButtonLandscape setImage:lockImage
//                                        forState:UIControlStateNormal];
//    }
}

- (IBAction)toggleScreenLockStatus:(id)sender
{
    [self adjustScreenLockImage];
    [self adjustOrientation];
    //当前视图可能不是UIWindow的第一个子视图，因此起interface orientation属性不正确，需要使用root view controller的orientation进行锁定屏幕。
    //[[SBScreenLocker sharedScreenLocker] toggleOrFixOrientationFromViewController:[ViewUtil rootViewController]];
}

- (IBAction)showMoreAction:(id)sender {
    NSString *title = [[[_mediaPlayer media] url] lastPathComponent];
    _moreActionSheet = [[UIActionSheet alloc]initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
//    [_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"PLAYBACK_SPEED", SB_MESSAGE_FILE, @"")];
//    [_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"VIDEO_FILTER", SB_MESSAGE_FILE, @"")];
    [_moreActionSheet addButtonWithTitle:@"PLAYBACK_SPEED"];
    [_moreActionSheet addButtonWithTitle:@"VIDEO_FILTER"];

    //仅当存在两个以上的音频轨道时才让用户选择
    if ([[_mediaPlayer audioTrackIndexes] count] > 2) {
        //[_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"CHOOSE_AUDIO_TRACK", SB_MESSAGE_FILE, @"")];
        [_moreActionSheet addButtonWithTitle:@"CHOOSE_AUDIO_TRACK"];
    }
    //仅当存在一个以上的字幕轨道时才让用户选择
    if ([[_mediaPlayer videoSubTitlesIndexes] count] > 1) {
        //[_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"CHOOSE_SUBTITLE_TRACK", SB_MESSAGE_FILE, @"")];
        [_moreActionSheet addButtonWithTitle:@"CHOOSE_SUBTITLE_TRACK"];
    }
//    [_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Media Information", SB_MESSAGE_FILE, @"")];
//    [_moreActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"BUTTON_CANCEL", SB_MESSAGE_FILE, @"")];
    //[_moreActionSheet addButtonWithTitle:@"Media Information"];
    [_moreActionSheet addButtonWithTitle:@"BUTTON_CANCEL"];
    [_moreActionSheet setCancelButtonIndex:[_moreActionSheet numberOfButtons] - 1];
    CGRect rectForShow = [self.moreActionButton convertRect:self.moreActionButton.bounds toView:self.view];
    [_moreActionSheet showFromRect:rectForShow inView:self.view animated:YES];
}

- (void)endPlaybackTimer:(id)sender{
    if (_shouldEndPlay) {
        [_shouldEndPlay invalidate];
        _shouldEndPlay = nil;
        _canEndPlay = YES;
    }
}

- (void)miniTVClosePlayback:(id)sender{
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
    [self _stopPlayback];
    //隐藏小电视
    //[VLCMiniTVDisplayView shareMiniTVDiaplayView].hidden = YES;
    [self setControlsHidden:NO animated:NO];
    if([self.movieViewControllerDelegate respondsToSelector:@selector(moviePlayerDidFinish:)]) {
        [self.movieViewControllerDelegate moviePlayerDidFinish:self];
    }
    //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)closePlayback:(id)sender
{
    if (!_canEndPlay) {
        
        return;
    }
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
    [self _stopPlayback];
    //隐藏小电视
    //[VLCMiniTVDisplayView shareMiniTVDiaplayView].hidden = YES;
    [self setControlsHidden:NO animated:NO];
    if([self.movieViewControllerDelegate respondsToSelector:@selector(moviePlayerDidFinish:)]) {
        [self.movieViewControllerDelegate moviePlayerDidFinish:self];
    }
    //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    VLCTime *newPosition = self.mediaPlayer.remainingTime;
    self.remainTimeLabel.text = newPosition.stringValue;
    _positionSet = NO;
    [self _resetIdleTimer];
}

- (void)_setPositionForReal
{
    if (!_positionSet) {
        _mediaPlayer.position = _positionSlider.value;
        _positionSet = YES;
    }
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    [self _updateScrubLabel];
    self.scrubIndicatorView.hidden = NO;
    _isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    self.scrubIndicatorView.hidden = YES;
    _isScrubbing = NO;
}

- (void)_updateScrubLabel
{
    float speed = self.positionSlider.scrubbingSpeed;
//    if (speed == 1.)
//        self.currentScrubSpeedLabel.text = NSLocalizedStringFromTable(@"PLAYBACK_SCRUB_HIGH", SB_MESSAGE_FILE, @"");
//    else if (speed == .5)
//        self.currentScrubSpeedLabel.text = NSLocalizedStringFromTable(@"PLAYBACK_SCRUB_HALF", SB_MESSAGE_FILE, @"");
//    else if (speed == .25)
//        self.currentScrubSpeedLabel.text = NSLocalizedStringFromTable(@"PLAYBACK_SCRUB_QUARTER", SB_MESSAGE_FILE, @"");
//    else
//        self.currentScrubSpeedLabel.text = NSLocalizedStringFromTable(@"PLAYBACK_SCRUB_FINE", SB_MESSAGE_FILE, @"");
    if (speed == 1.)
        self.currentScrubSpeedLabel.text = @"PLAYBACK_SCRUB_HIGH";
    else if (speed == .5)
        self.currentScrubSpeedLabel.text = @"PLAYBACK_SCRUB_HALF";
    else if (speed == .25)
        self.currentScrubSpeedLabel.text = @"PLAYBACK_SCRUB_QUARTER";
    else
        self.currentScrubSpeedLabel.text = @"PLAYBACK_SCRUB_FINE";

    
    [self _resetIdleTimer];
}

- (IBAction)positionSliderDrag:(id)sender
{
    [self _updateScrubLabel];
}

- (IBAction)volumeSliderAction:(id)sender
{
    [self _resetIdleTimer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"shouldAutoRotate"]) {
        [self adjustScreenLockImage];
    } else if ([keyPath isEqualToString:KEY_PATH_MEDIA_PLAYER_TIME]) {
        self.elapsedTimeLabel.text = [[_mediaPlayer time] stringValue];
    } else if ([keyPath isEqualToString:KEY_PATH_MEDIA_PLAYER_REMAINING_TIME]) {
        self.remainTimeLabel.text = [[_mediaPlayer remainingTime] stringValue];
    } else {
        SBDebugLog(@"keypath = %@, object = %@, change = %@", keyPath, object, change);
    }
    if (!_isScrubbing) {
        self.positionSlider.value = [_mediaPlayer position];
    }
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;
    SBDebugLog(@"%@", VLCMediaPlayerStateToString(currentState));
    if (currentState == VLCMediaPlayerStateBuffering) {
        /* attach delegate */
        _mediaPlayer.media.delegate = self;
        /* let's update meta data */
        [self _updateDisplayedMetadata];
    }
    
    if (currentState == VLCMediaPlayerStateError) {
//        [self.statusLabel showStatusMessage:NSLocalizedStringFromTable(@"PLAYBACK_FAILED", SB_MESSAGE_FILE, @"")];
        [self.statusLabel showStatusMessage:@"PLAYBACK_FAILED"];
        //[self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.];
    }
    
    if (currentState == VLCMediaPlayerStateStopped || currentState == VLCMediaPlayerStateEnded) {
//        [self.mediaPlayer setPosition:_currentMediaItem.starttime/(self.mediaPlayer.time.intValue + self.mediaPlayer.remainingTime.intValue)];
    }
    
    if ((currentState == VLCMediaPlayerStateStopped || currentState == VLCMediaPlayerStateEnded) && _mediaPlayer.position >= 1.0) {
        [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
//        SBMediaItem *item = [self nextMediaItem];
//        if (item) {
//            [self playMedia:item];
//        }else{
//            
//            [self _stopPlayback];
//            if (self.isInMiniTVMode) {
//                VLCMiniTVDisplayView *mini = [VLCMiniTVDisplayView shareMiniTVDiaplayView];
//                mini.hidden = YES;
//                [[SBGPMediaPlayer shareMediaPlayer] stopPlay];
//                self.view.hidden = NO;
//                self.inMiniTVMode = NO;
//            }else{
//                //隐藏小电视
//                [VLCMiniTVDisplayView shareMiniTVDiaplayView].hidden = YES;
//                [self setControlsHidden:NO animated:NO];
//                if([self.movieViewControllerDelegate respondsToSelector:@selector(moviePlayerDidFinish:)]) {
//                    [self.movieViewControllerDelegate moviePlayerDidFinish:self];
//                }
//                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//            }
//        }
    }
    
//    UIImage *playPauseImage = [_mediaPlayer isPlaying]? [PlayerFramework loadImage:@"pauseIcon.png"] : [PlayerFramework loadImage:@"playIcon.png"];
    UIImage *playPauseImage = [_mediaPlayer isPlaying]? [UIImage imageNamed:@"pauseIcon.png"] : [UIImage imageNamed:@"playIcon.png"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
    [_playPauseButtonLandscape setImage:playPauseImage forState:UIControlStateNormal];
    
    if ([[_mediaPlayer audioTrackIndexes] count] > 2) {
        self.audioSwitcherButton.hidden = NO;
        self.audioSwitcherButtonLandscape.hidden = NO;
    } else {
        self.audioSwitcherButton.hidden = YES;
        self.audioSwitcherButtonLandscape.hidden = YES;
    }
    
    if ([[_mediaPlayer videoSubTitlesIndexes] count] > 1) {
        self.subtitleContainer.hidden = NO;
        self.subtitleContainerLandscape.hidden = NO;
    } else {
        self.subtitleContainer.hidden = YES;
        self.subtitleContainerLandscape.hidden = YES;
    }
}

- (IBAction)playPause
{
    if ([self.mediaPlayer isPlaying]) {
        [self.mediaPlayer pause];
    } else {
        [self.mediaPlayer play];
    }
}

- (IBAction)forward:(id)sender
{
    if (_shouldPlayNext && _shouldPlayNextTimer == nil) {
        _shouldPlayNext = NO;
        _shouldPlayNextTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
        SBDebugLog(@"forward:yes");
    }else{
        SBDebugLog(@"forward:no");
        return;
    }
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
//    SBMediaItem *nextMedia = [self nextMediaItem];
//    if(nextMedia) {
//        [self playMedia:nextMedia];
//    } else {
//        //[self.statusLabel showStatusMessage:NSLocalizedStringFromTable(@"It is the last media.", SB_MESSAGE_FILE, @"已经是最后一个媒体了")];
//        [self.statusLabel showStatusMessage:@"It is the last media."];
//    }
}

- (IBAction)backward:(id)sender
{
    if (_shouldPlayNext && _shouldPlayNextTimer == nil) {
        _shouldPlayNext = NO;
        _shouldPlayNextTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
        SBDebugLog(@"backward:yes");
    }else{
        SBDebugLog(@"backward:no");
        return;
    }
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
//    SBMediaItem *previousMedia = [self previousMediaItem];
//    if(previousMedia) {
//        [self playMedia:previousMedia];
//    } else {
//        //[self.statusLabel showStatusMessage:NSLocalizedStringFromTable(@"It is the first media.", SB_MESSAGE_FILE, @"已经是第一个媒体了")];
//        [self.statusLabel showStatusMessage:@"It is the first media."];
//    }
}



- (IBAction)switchSubtitleTrack:(id)sender
{
    if(sender != self.subtitleSwitcherButton && sender != self.subtitleSwitcherButtonLandscape) return;
    UIButton *button = (UIButton *)sender;
    NSArray *spuTracks = [_mediaPlayer videoSubTitlesNames];
    NSArray *spuTrackIndexes = [_mediaPlayer videoSubTitlesIndexes];
    
    NSUInteger count = [spuTracks count];
    if (count <= 1)
        return;
//    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable(@"CHOOSE_SUBTITLE_TRACK", SB_MESSAGE_FILE, @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:@"CHOOSE_SUBTITLE_TRACK" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *indexIndicator = ([spuTrackIndexes[i] intValue] == [_mediaPlayer currentVideoSubTitleIndex])? @"\u2713": @"";
        NSString *buttonTitle = [NSString stringWithFormat:@"%@ %@", indexIndicator, spuTracks[i]];
        [_subtitleActionSheet addButtonWithTitle:buttonTitle];
    }
    
//    [_subtitleActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"BUTTON_CANCEL", SB_MESSAGE_FILE, @"cancel button")];
    [_subtitleActionSheet addButtonWithTitle:@"BUTTON_CANCEL"];
    [_subtitleActionSheet setCancelButtonIndex:[_subtitleActionSheet numberOfButtons] - 1];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //        [_subtitleActionSheet showInView:(UIButton *)sender];
        CGRect rectForShow = [button convertRect:button.bounds toView:self.view];
        [_subtitleActionSheet showFromRect:rectForShow inView:self.view animated:YES];
    } else {
        [_subtitleActionSheet showInView:self.view];
    }
}

#pragma mark - Playlist


//- (SBMediaItem *)nextMediaItem {
//    id<SBMediaSelector> mediaSelector = [[SBMediaSelectorCatalog sharedCatalog] mediaSelectorForPlayMode:self.playMode];
//    return [mediaSelector selectNextMediaItemFromPlaylist:self.playlist withCurrentMediaItem:self.currentMediaItem];
//}
//
//- (SBMediaItem *)previousMediaItem {
//    id<SBMediaSelector> mediaSelector = [[SBMediaSelectorCatalog sharedCatalog] mediaSelectorForPlayMode:self.playMode];
//    return [mediaSelector selectPreviousMediaItemFromPlaylist:self.playlist withCurrentMediaItem:self.currentMediaItem];
//}

- (SBMediaItem *)currentMediaItem {
    return _currentMediaItem;
}

#pragma mark - player control

- (void)play {
    [self.mediaPlayer play];
}

- (void)pause {
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
    [self.mediaPlayer pause];
}

- (void)stop {
    [self stopAtTime:self.mediaPlayer ? self.mediaPlayer.time.intValue:0.0];
    [self.mediaPlayer stop];
}

- (BOOL)isPlaying {
    return [self.mediaPlayer isPlaying];
}

- (BOOL)beforeLoad{
    if([self.currentMediaItem.url isFileURL])
    {
//        NSNumber *watchFromLastTime = [[SBPreference sharedPreference] objectForKey:kSBWatchFromLastTime];
//        if([watchFromLastTime integerValue] == SBWachFromLastTime )
//        {
//            HistoryWatchDao *his = [HistoryWatchDao dao];
//            self.currentMediaItem.starttime = [his getWatchHistory:[self.currentMediaItem.url path]
//                                                                 objectid:self.currentMediaItem.objectid
//                                                               identifier:self.currentMediaItem.identifier];
//            APLog(@"%@ start time:%f",self.currentMediaItem.url,self.currentMediaItem.starttime);
//            return YES;
//        }
    }
    return NO;
}

- (float)duration{
    return self.mediaPlayer ? self.mediaPlayer.media.length.intValue : 0.0;
}

- (BOOL)stopAtTime:(float)time{
    if([self.currentMediaItem.url isFileURL]) {
//        APLog(@"%@ end time:%f",self.currentMediaItem.url,time);
//        if(fabs(time / [self duration])>0.9) {
//            APLog(@"Media(%f) reach end(%f),start from begin.",time,[self duration]);
//            time = 0.0f;
//        }
//        HistoryWatchDao *his = [HistoryWatchDao dao];
//        return [his updateWatchHistory:[self.currentMediaItem.url path]
//                                  time:time/1000.0
//                              objectid:self.currentMediaItem.objectid
//                            identifier:self.currentMediaItem.identifier];
        
    }
    return YES;
}

- (void)onTimer:(id)sender{
    if (_shouldPlayNextTimer) {
        [_shouldPlayNextTimer invalidate];
        _shouldPlayNextTimer = nil;
        _shouldPlayNext = YES;
    }
}

- (void)playMedia:(SBMediaItem *)mediaItem {
    if(mediaItem) {
        self.currentMediaItem = mediaItem;
//        BOOL isWatchFromLastTime = [self beforeLoad];
        VLCMedia *media = [[VLCMedia alloc]initWithURL:mediaItem.url];
        [self setupMediaPlayer];
        self.mediaPlayer.media = media;
        
        // 添加通知，更新下载文件提示
        [[NSNotificationCenter defaultCenter] postNotificationName:SBNotificationDownloadFileDidPlay object:[mediaItem.url path]];
        
        //如果是M3u8直接播放
        NSString *strExt = [[mediaItem.url pathExtension] lowercaseString];
        if([strExt isEqualToString:@"m3u8"])
        {
        //if (0) {//[FileManager isSystemFileItemM3U8Package:[[mediaItem.url path] stringByDeletingLastPathComponent]]
            NSDictionary *mediaOptions = [self mediaOptionsForMedia:media];
            [media addOptions:mediaOptions];
            [self.mediaPlayer play];
            [self _updateDisplayedMetadata];
            return;
        }
        
        _media = media;
        self.mediaPlayer.media.delegate = self;
        [self.mediaPlayer.media parse];
    }
}


- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    _media = nil;
    SBDebugLog(@"%@", aMedia.length);
   

    VLCMedia *media = self.mediaPlayer.media;
    NSDictionary *mediaOptions = [self mediaOptionsForMedia:media];
    [media addOptions:mediaOptions];
    [self.mediaPlayer play];
    media.delegate = nil;
    //如果支持记忆播放，则从上一次播放进度开始播放
    BOOL isWatchFromLastTime = [self beforeLoad];
    if (isWatchFromLastTime && self.mediaPlayer.media.length.intValue > 0) {
        SBDebugLog(@"%d", self.mediaPlayer.media.length.intValue);
        SBDebugLog(@"%f", self.currentMediaItem.starttime);
        self.mediaPlayer.position = self.currentMediaItem.starttime/(self.mediaPlayer.media.length.intValue/1000);
    }
    [self _updateDisplayedMetadata];
}

- (NSDictionary *)mediaOptionsForMedia:(VLCMedia *)media {
    NSMutableDictionary *mediaDictionary = [[NSMutableDictionary alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [mediaDictionary setObject:[[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue forKey:kVLCSettingStretchAudio];
    if([defaults objectForKey:kVLCSettingTextEncoding]!=nil)//Added by GH at 20140908
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingTextEncoding] forKey:kVLCSettingTextEncoding];
    if([defaults objectForKey:kVLCSettingSkipLoopFilter]!=nil)//Added by GH at 20140908
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingSkipLoopFilter] forKey:kVLCSettingSkipLoopFilter];
    
    //BOOL canDecodeCopyrightAudio = [[[SBPreference sharedPreference]objectForKey:kSBCanDecodeCopyrightAudio] boolValue];
    //如果不允许解码受版权保护的音频，则屏蔽并提示用户
    BOOL canDecodeCopyrightAudio=NO;
    if (!canDecodeCopyrightAudio) {
        BOOL noAudio = NO;
        NSArray *tracksInfo = media.tracksInformation;
        if(tracksInfo.count <= 0 && [media.url isFileURL]) {
            noAudio = YES;
        }
        for (NSUInteger x = 0; x < tracksInfo.count; x++) {
            if ([[tracksInfo[x] objectForKey:VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeAudio])
            {
                NSInteger fourcc = [[tracksInfo[x] objectForKey:VLCMediaTracksInformationCodec] integerValue];
                
                switch (fourcc) {
                    case 540161377:
                    case 1647457633:
                    case 858612577:
                    case 862151027:
                    case 862151013:
                    case 1684566644:
                    case 2126701:
                    {
                        noAudio = YES;
                        break;
                    }
                    default:
                        break;
                }
            }
        }
        if (noAudio) {
            [mediaDictionary setObject:[NSNull null] forKey:@"no-audio"];
            APLog(@"audio playback disabled because an unsupported codec was found");
//            NSString *msg = NSLocalizedStringFromTable(@"该媒体的音频编码受版权保护，我们将不对其进行解码。", SB_MESSAGE_FILE, @"该媒体的音频编码受版权保护，我们将不对其进行解码。");
//            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:MESSAGE_REMIND_INFO message:msg delegate:nil cancelButtonTitle:MESSAGE_DONE otherButtonTitles:nil];
//            [alertView show];
        }
    }
    return mediaDictionary;
}

- (void)playMediaAtIndex:(NSInteger)index {
    [self playMedias:self.playlist atIndex:index];
}

- (void)playMedias:(NSArray *)medias atIndex:(NSInteger)index {
    if (medias.count <= 0) {
        return;
    }
    if(index < 0 || index >= medias.count) {
        //指定的索引无效时，播放第一个媒体
//        APLog(@"Index(%d) not in range[0 - %d], will set index = 0 and play.", index, medias.count - 1);
        index = 0;
        [self.playlist removeAllObjects];
        [self.playlist addObjectsFromArray:medias];
    }
    
    SBMediaItem *item = self.playlist[index];
    [self playMedia:item];
}

- (void)addMediasToPlaylist:(NSArray *)medias {
    [self.playlist addObjectsFromArray:medias];
}

- (void)setupMediaPlayer {
    if(_mediaPlayer == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //NSLog(@"defaults=%@",defaults);
        NSArray *playerOptions = @[[NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFont, [defaults objectForKey:kVLCSettingSubtitlesFont]],
                                   [NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFontColor, [defaults objectForKey:kVLCSettingSubtitlesFontColor]],
                                   [NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFontSize, [defaults objectForKey:kVLCSettingSubtitlesFontSize]],
                                   [NSString stringWithFormat:@"--%@=%@", kVLCSettingDeinterlace, [defaults objectForKey:kVLCSettingDeinterlace]],
                                   [NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkCaching, [defaults objectForKey:kVLCSettingNetworkCaching]]
                                   ];
        _mediaPlayer = [[VLCMediaPlayer alloc]initWithOptions:playerOptions];
        [_mediaPlayer setDelegate:self];
        [_mediaPlayer setDrawable:self.movieView];
    }
}

#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [actionSheet cancelButtonIndex])
        return;
    
    NSArray *indexArray;
    if (actionSheet == _subtitleActionSheet) {
        indexArray = _mediaPlayer.videoSubTitlesIndexes;
        if (buttonIndex <= indexArray.count) {
            _mediaPlayer.currentVideoSubTitleIndex = [indexArray[buttonIndex] intValue];
        }
    } else if (actionSheet == _audiotrackActionSheet) {
        indexArray = _mediaPlayer.audioTrackIndexes;
        if (buttonIndex <= indexArray.count) {
            _mediaPlayer.currentAudioTrackIndex = [indexArray[buttonIndex] intValue];
        }
    } else if (actionSheet == _moreActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
//        if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"PLAYBACK_SPEED", SB_MESSAGE_FILE, @"")]) {
//            [self videoDimensionAction:nil];
//        } else if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"VIDEO_FILTER", SB_MESSAGE_FILE, @"")]) {
//            [self videoFilterToggle:nil];
//        } else if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"CHOOSE_AUDIO_TRACK", SB_MESSAGE_FILE, @"")]) {
//            [self switchAudioTrack:nil];
//        } else if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"CHOOSE_SUBTITLE_TRACK", SB_MESSAGE_FILE, @"")]) {
//            [self switchSubtitleTrack:nil];
//        } else if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"Media Information", SB_MESSAGE_FILE, @"")]) {
//            [self showMediaInfo:nil];
//        } else if([buttonTitle isEqualToString:NSLocalizedStringFromTable(@"BUTTON_CANCEL", SB_MESSAGE_FILE, @"")]) {
//            //
//        }
        if([buttonTitle isEqualToString:@"PLAYBACK_SPEED"]) {
            [self videoDimensionAction:nil];
        } else if([buttonTitle isEqualToString:@"VIDEO_FILTER"]) {
            [self videoFilterToggle:nil];
        } else if([buttonTitle isEqualToString:@"CHOOSE_AUDIO_TRACK"]) {
            [self switchAudioTrack:nil];
        } else if([buttonTitle isEqualToString:@"CHOOSE_SUBTITLE_TRACK"]) {
            [self switchSubtitleTrack:nil];
        } else if([buttonTitle isEqualToString:@"Media Information"]) {
            [self showMediaInfo:nil];
        } else if([buttonTitle isEqualToString:@"BUTTON_CANCEL"]) {
            //
        }
    }
}

#pragma mark - Transform For Orientation
#define DegreesToRadians(degrees) (degrees * M_PI / 180)

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation {
    
    switch (orientation) {
            
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(-DegreesToRadians(90));
            
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(DegreesToRadians(90));
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(DegreesToRadians(180));
            
        case UIInterfaceOrientationPortrait:
        default:
            return CGAffineTransformMakeRotation(DegreesToRadians(0));
    }
}

- (void)statusBarDidChangeFrame:(NSNotification *)notification {
    [self adjustOrientation];
}

- (void)adjustOrientation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGAffineTransform theNewTransform = [self transformForOrientation:orientation];
    [self.view setTransform:theNewTransform];
    UIWindow *window=[[UIWindow alloc]init];
    NSArray *windows = [[UIApplication sharedApplication] windows];
    if(windows.count > 0) {
        window=[windows objectAtIndex:0];
    } else {
        window=nil;
    }
    self.view.frame = window.bounds;
}
#pragma mark - multi-touch gestures

- (void)tapRecognized
{
    if ([self.mediaPlayer isPlaying]) {
        [self.mediaPlayer pause];
        [self.statusLabel showStatusMessage:@"  ▌▌ "];
    } else {
        [self.mediaPlayer play];
        [self.statusLabel showStatusMessage:@" ► "];
    }
}

- (NSString*)detectPanTypeForPan:(UIPanGestureRecognizer*)panRecognizer
{
    NSString * type;
    NSString * deviceType = [[UIDevice currentDevice] model];
    type = @"Volume"; // default in case of error
    CGPoint location = [panRecognizer locationInView:self.view];
    CGFloat position = location.x;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = .0;
    if (UIDeviceOrientationIsPortrait(orientation)) {
        screenWidth = screenRect.size.width;
    } else {
        screenWidth = screenRect.size.height;
    }
    
    if (position < screenWidth / 2)
        type = @"Brightness";
    if (position > screenWidth / 2)
        type = @"Volume";
    
    // only check for seeking gesture if on iPad , will overwrite last statements if true
    if ([deviceType isEqualToString:@"iPad"]) {
        if (location.y < 110)
            type = @"Seek";
    }
    
    return type;
}

- (void)panRecognized:(UIPanGestureRecognizer*)panRecognizer
{
    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;
    
    if (panRecognizer.state == UIGestureRecognizerStateBegan) // Only Detect pantype when began to allow more freedom
        panType = [self detectPanTypeForPan:panRecognizer];
    
    if ([panType isEqual:@"Seek"]) {
        double timeRemainingDouble = (-_mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;
        
        if (panDirectionX > 0) {
            if (timeRemaining > 2 ) // to not go outside duration , video will stop
                [_mediaPlayer jumpForward:1];
        } else
            [_mediaPlayer jumpBackward:1];
    } else if ([panType isEqual:@"Volume"]) {
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (panDirectionY > 0)
            musicPlayer.volume -= 0.01;
        else
            musicPlayer.volume += 0.01;
    } else if ([panType isEqual:@"Brightness"]) {
        CGFloat brightness = [UIScreen mainScreen].brightness;
        if (panDirectionY > 0)
            [[UIScreen mainScreen] setBrightness:(brightness - 0.01)];
        else
            [[UIScreen mainScreen] setBrightness:(brightness + 0.01)];
        self.brightnessSlider.value = [[UIScreen mainScreen] brightness] * 2;
        //NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", NSLocalizedStringFromTable(@"VFILTER_BRIGHTNESS", SB_MESSAGE_FILE, @""), [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
        NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", @"VFILTER_BRIGHTNESS", [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
        [self.statusLabel showStatusMessage:brightnessHUD];
    }
    
    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.mediaPlayer isPlaying]) {
            [self.mediaPlayer play];
        }
    }
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    NSString * hudString = @" ";
    
    if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        double timeRemainingDouble = (-_mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;
        
        if (FORWARD_SWIPE_DURATION < timeRemaining) {
            [_mediaPlayer jumpForward:FORWARD_SWIPE_DURATION];
            hudString = [NSString stringWithFormat:@"⇒ %is", FORWARD_SWIPE_DURATION];
        } else {
            [_mediaPlayer jumpForward:(timeRemaining - 5)];
            hudString = [NSString stringWithFormat:@"⇒ %is",(timeRemaining - 5)];
        }
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [_mediaPlayer jumpBackward:BACKWARD_SWIPE_DURATION];
        hudString = [NSString stringWithFormat:@"⇐ %is",BACKWARD_SWIPE_DURATION];
    }
    
    if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.mediaPlayer isPlaying]) {
            [self.mediaPlayer play];
        }
        
        [self.statusLabel showStatusMessage:hudString];
    }
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
            self.controllerPanelLandscape.hidden = YES;
        }
    }
    
    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    if (sender == self.hueSlider)
        _mediaPlayer.hue = (int)self.hueSlider.value;
    else if (sender == self.contrastSlider)
        _mediaPlayer.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider) {
        if ([self hasExternalDisplay])
            _mediaPlayer.brightness = self.brightnessSlider.value;
        else
            [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
    } else if (sender == self.saturationSlider)
        _mediaPlayer.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        _mediaPlayer.gamma = self.gammaSlider.value;
    else if (sender == self.resetVideoFilterButton) {
        _mediaPlayer.hue = self.hueSlider.value = 0.;
        _mediaPlayer.contrast = self.contrastSlider.value = 1.;
        _mediaPlayer.brightness = self.brightnessSlider.value = 1.;
        [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
        _mediaPlayer.saturation = self.saturationSlider.value = 1.;
        _mediaPlayer.gamma = self.gammaSlider.value = 1.;
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self _resetIdleTimer];
}

#pragma mark - playback view
- (IBAction)playbackSpeedSliderAction:(UISlider *)sender
{
    double speed = pow(2, sender.value / 17.);
    float rate = INPUT_RATE_DEFAULT / speed;
    if (_currentPlaybackRate != rate)
        [_mediaPlayer setRate:INPUT_RATE_DEFAULT / rate];
    _currentPlaybackRate = rate;
    [self _updatePlaybackSpeedIndicator];
    [self _resetIdleTimer];
}

- (void)_updatePlaybackSpeedIndicator
{
    float f_value = self.playbackSpeedSlider.value;
    double speed =  pow(2, f_value / 17.);
    self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", speed];
    
    /* rate changed, so update the exported info */
    [self performSelectorInBackground:@selector(_updateDisplayedMetadata) withObject:nil];
}

- (float)_playbackSpeed
{
    float f_rate = _mediaPlayer.rate;
    
    double value = 17 * log(f_rate) / log(2.);
    float returnValue = (int) ((value > 0) ? value + .5 : value - .5);
    
    if (returnValue < -34.)
        returnValue = -34.;
    else if (returnValue > 34.)
        returnValue = 34.;
    
    _currentPlaybackRate = returnValue;
    return returnValue;
}

- (IBAction)videoDimensionAction:(id)sender
{
    if (sender == self.playbackSpeedButton || sender == self.playbackSpeedButtonLandscape) {
        if (!_videoFiltersHidden)
            self.videoFilterView.hidden = _videoFiltersHidden = YES;
        
        self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
        _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
        [self _resetIdleTimer];
    } else if (sender == self.aspectRatioButton) {
        [self toggleVideoDimension];
    }
}

- (void)toggleVideoDimension {
    NSUInteger count = [_aspectRatios count];
//    __block BOOL done = wait; //wait =  YES wait to finish animation
//    self.movieViewContainer.transform = CGAffineTransformMakeScale(0.85, 0.85);
//    [UIView animateWithDuration:0.5 animations:^{
//        self.movieViewContainer.transform = CGAffineTransformIdentity;
//        //view.transform = CGAffineTransformMakeScale(0, 0);
//        //view.transform = CGAffineTransformIdentity;
//
//    } completion:^(BOOL finished) {
//        done = NO;
//    }];
//    // wait for animation to finish
//    while (done == YES)
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    if (_currentAspectRatioMask + 1 > count - 1) {
        _mediaPlayer.videoAspectRatio = NULL;
        _mediaPlayer.videoCropGeometry = NULL;
        _currentAspectRatioMask = 0;
//        [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"AR_CHANGED", SB_MESSAGE_FILE, @""), NSLocalizedStringFromTable(@"DEFAULT", SB_MESSAGE_FILE, @"")]];
        [self.statusLabel showStatusMessage:[NSString stringWithFormat:@"AR_CHANGED"]];
    } else {
        _currentAspectRatioMask++;
        
        if ([_aspectRatios[_currentAspectRatioMask] isEqualToString:@"FILL_TO_SCREEN"]) {
            UIScreen *screen;
            if (![self hasExternalDisplay])
                screen = [UIScreen mainScreen];
            else
                screen = [UIScreen screens][1];
            
            float f_ar = screen.bounds.size.width / screen.bounds.size.height;
            if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
            {   // 竖屏
                if (f_ar == (float)(640./1136.)) // iPhone 5 aka 16:9.01
                    _mediaPlayer.videoCropGeometry = "9:16";
                else if (f_ar == (float)(2./3.)) // all other iPhones
                    _mediaPlayer.videoCropGeometry = "10:16"; // libvlc doesn't support 2:3 crop
                else if (f_ar == .75) // all iPads
                    _mediaPlayer.videoCropGeometry = "3:4";
                else if (f_ar == .5625) // AirPlay
                    _mediaPlayer.videoCropGeometry = "9:16";
                else
                    APLog(@"unknown screen format %f, can't crop", f_ar);
            }
            else{ // 横屏
                if (f_ar == (float)(640./1136.)) // iPhone 5 aka 16:9.01
                    _mediaPlayer.videoCropGeometry = "16:9";
                else if (f_ar == (float)(2./3.)) // all other iPhones
                    _mediaPlayer.videoCropGeometry = "16:10"; // libvlc doesn't support 2:3 crop
                else if (f_ar == .75) // all iPads
                    _mediaPlayer.videoCropGeometry = "4:3";
                else if (f_ar == .5625) // AirPlay
                    _mediaPlayer.videoCropGeometry = "16:9";
                else
                    APLog(@"unknown screen format %f, can't crop", f_ar);
            }
//            [self.statusLabel showStatusMessage:NSLocalizedStringFromTable(@"FILL_TO_SCREEN", SB_MESSAGE_FILE, @"")];
            [self.statusLabel showStatusMessage:@"FILL_TO_SCREEN"];
            return;
        }
        _mediaPlayer.videoCropGeometry = NULL;
        _mediaPlayer.videoAspectRatio = (char *)[_aspectRatios[_currentAspectRatioMask] UTF8String];
//        [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"AR_CHANGED", SB_MESSAGE_FILE, @""), _aspectRatios[_currentAspectRatioMask]]];
        [self.statusLabel showStatusMessage:[NSString stringWithFormat:@"%@", _aspectRatios[_currentAspectRatioMask]]];
    }
    
}

#pragma mark - background interaction

- (void)configPlayingInfo
{
    NSDictionary * metaDict = _mediaPlayer.media.metaDictionary;
    if (!metaDict) {
        return;
    }
    NSString *title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
    NSString *artist = metaDict[VLCMetaInformationArtist];
    NSString *albumName = metaDict[VLCMetaInformationAlbum];
    NSString *trackNumber = metaDict[VLCMetaInformationTrackNumber];
    
    if (title == nil || [title isEqualToString:@""]) {
        title = [NSString stringWithFormat:@"%@",[[self.currentMediaItem.url path] lastPathComponent]];
    }
    NSMutableDictionary *currentlyPlayingTrackInfo;
    currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: title, MPMediaItemPropertyTitle, @(_mediaPlayer.media.length.intValue / 1000.), MPMediaItemPropertyPlaybackDuration, @(_mediaPlayer.time.intValue / 1000.), MPNowPlayingInfoPropertyElapsedPlaybackTime, @(_mediaPlayer.rate), MPNowPlayingInfoPropertyPlaybackRate, nil];
    if (artist.length > 0)
        [currentlyPlayingTrackInfo setObject:artist forKey:MPMediaItemPropertyArtist];
    if (albumName.length > 0)
        [currentlyPlayingTrackInfo setObject:albumName forKey:MPMediaItemPropertyAlbumTitle];
    [currentlyPlayingTrackInfo setObject:[NSNumber numberWithInt:[trackNumber intValue]] forKey:MPMediaItemPropertyAlbumTrackNumber];
    if (self.artworkImageView.image) {
        MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImageView.image];
        [currentlyPlayingTrackInfo setObject:mpartwork forKey:MPMediaItemPropertyArtwork];
    }
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    [self configPlayingInfo]; //添加音频锁屏封面
    
//    _mediaPlayer.delegate = nil;
//    _mediaPlayer.currentVideoTrackIndex = 0;
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue]) {
        if ([_mediaPlayer isPlaying]) {
            [_mediaPlayer pause];
            _shouldResumePlaying = YES;
        }
    }
    
}

//进入前台开始绘制图像
- (void)applicationWillEnterForeground:(NSNotification *)notification{
    BOOL hasOpenGLView = NO;
    for (UIView *view in self.movieView.subviews) {
        if ([NSStringFromClass([view class]) isEqualToString:@"VLCOpenGLES2VideoView"]) {
            hasOpenGLView = YES;
            [self.mediaPlayer setDrawable:self.movieView];
            return;
        }
    }
    if (hasOpenGLView == NO) {
        if (_mediaPlayer) {
            @try {
                [_mediaPlayer removeObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_TIME];
                [_mediaPlayer removeObserver:self forKeyPath:KEY_PATH_MEDIA_PLAYER_REMAINING_TIME];
            }
            @catch (NSException *exception) {
                APLog(@"we weren't an observer yet");
            }
            
            if (_mediaPlayer.media) {
                [self stopAtTime:self.mediaPlayer.time.intValue];
                [_mediaPlayer stop];
            }
            self.mediaPlayer = nil;
        }
        [self playMedia:self.currentMediaItem];
    }
}

//进入后台停止绘制图像
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
//    _mediaPlayer.currentVideoTrackIndex = -1;
    _shouldResumePlaying = NO;
    [_mediaPlayer setDrawable:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
//    _mediaPlayer.currentVideoTrackIndex = 1;
    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        
        [self.mediaPlayer play];
    }
}


- (void)_updateDisplayedMetadata
{
    NSString *title;
    NSString *artist;
    NSString *albumName;
    NSString *trackNumber;

    NSDictionary * metaDict = _mediaPlayer.media.metaDictionary;

    if (metaDict) {
        title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
        artist = metaDict[VLCMetaInformationArtist];
        albumName = metaDict[VLCMetaInformationAlbum];
        trackNumber = metaDict[VLCMetaInformationTrackNumber];
        UIImage *artwork = [VLCThumbnailsCache thumbnailForMediaItemWithTitle:title Artist:artist andAlbumName:albumName];
        if (artwork == nil && ([title isSupportedAudioMediaFormat])) {
            // 音频文件添加默认播放封面图
            artwork = [UIImage imageNamed:@"default_music_play_background.png"];
        }
        [self.artworkImageView performSelectorOnMainThread:@selector(setImage:) withObject:artwork waitUntilDone:NO];
    }

    if (!self.artworkImageView.image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.trackNameLabel.text = title;
            self.artistNameLabel.text = artist;
            self.albumNameLabel.text = albumName;
        });
    } else {
        NSString *trackName = title;
        if (artist)
            trackName = [trackName stringByAppendingFormat:@" — %@", artist];
        if (albumName)
            trackName = [trackName stringByAppendingFormat:@" — %@", albumName];
        [self.trackNameLabel performSelectorOnMainThread:@selector(setText:) withObject:trackName waitUntilDone:NO];
    }
    
    if (self.trackNameLabel.text.length < 1) {
        NSString *trackName = [[_mediaPlayer.media url] lastPathComponent];
        [self.trackNameLabel performSelectorOnMainThread:@selector(setText:) withObject:trackName waitUntilDone:NO];
    }
    
    /* don't leak sensitive information to the OS, if passcode lock is enabled */
    BOOL passcodeLockEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingPasscodeOnKey] boolValue];
    
    NSMutableDictionary *currentlyPlayingTrackInfo;
    if (passcodeLockEnabled) {
        currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(_mediaPlayer.media.length.intValue / 1000.), MPMediaItemPropertyPlaybackDuration, @(_mediaPlayer.time.intValue / 1000.), MPNowPlayingInfoPropertyElapsedPlaybackTime, @(_mediaPlayer.rate), MPNowPlayingInfoPropertyPlaybackRate, nil];
    } else {
        if (title == nil || [title isEqualToString:@""]) {
            title = [NSString stringWithFormat:@"%@",[[self.currentMediaItem.url path] lastPathComponent]];
        }
        currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: title, MPMediaItemPropertyTitle, @(_mediaPlayer.media.length.intValue / 1000.), MPMediaItemPropertyPlaybackDuration, @(_mediaPlayer.time.intValue / 1000.), MPNowPlayingInfoPropertyElapsedPlaybackTime, @(_mediaPlayer.rate), MPNowPlayingInfoPropertyPlaybackRate, nil];
        if (artist.length > 0)
            [currentlyPlayingTrackInfo setObject:artist forKey:MPMediaItemPropertyArtist];
        if (albumName.length > 0)
            [currentlyPlayingTrackInfo setObject:albumName forKey:MPMediaItemPropertyAlbumTitle];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithInt:[trackNumber intValue]] forKey:MPMediaItemPropertyAlbumTrackNumber];
        if (self.artworkImageView.image) {
            MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImageView.image];
            [currentlyPlayingTrackInfo setObject:mpartwork forKey:MPMediaItemPropertyArtwork];
        }
    }
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

#pragma mark - autorotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (self.artworkImageView.image)
            self.trackNameLabel.hidden = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    }
}

#pragma mark - AVSession delegate
- (void)beginInterruption
{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue])
        _shouldResumePlaying = YES;
    
    [_mediaPlayer pause];
}

- (void)endInterruption
{
    if (_shouldResumePlaying) {
        [_mediaPlayer play];
        _shouldResumePlaying = NO;
    }
}

#pragma mark - External Display

- (BOOL)hasExternalDisplay
{
    return ([[UIScreen screens] count] > 1);
}

- (void)showOnExternalDisplay
{
    UIScreen *screen = [UIScreen screens][1];
    screen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;
    
    self.externalWindow = [[UIWindow alloc] initWithFrame:screen.bounds];
    
    UIViewController *controller = [[VLCExternalDisplayController alloc] init];
    self.externalWindow.rootViewController = controller;
    [controller.view addSubview:_movieView];
    controller.view.frame = screen.bounds;
    _movieView.frame = screen.bounds;
    
    self.playingExternallyView.hidden = NO;
    self.externalWindow.screen = screen;
    self.externalWindow.hidden = NO;
    
    [self.externalWindow makeKeyAndVisible];
}

- (void)hideFromExternalDisplay
{
    [self.view addSubview:_movieView];
    [self.view sendSubviewToBack:_movieView];
    _movieView.frame = self.view.frame;
    
    self.playingExternallyView.hidden = YES;
    self.externalWindow.hidden = YES;
    self.externalWindow = nil;
}

- (void)handleExternalScreenDidConnect:(NSNotification *)notification
{
    [self showOnExternalDisplay];
}

- (void)handleExternalScreenDidDisconnect:(NSNotification *)notification
{
    [self hideFromExternalDisplay];
}

@end
