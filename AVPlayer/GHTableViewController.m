//
//  GHTableViewController.m
//  AVPlayer
//
//  Created by ios on 14-9-5.
//  Copyright (c) 2014年 ios. All rights reserved.
//

#import "GHTableViewController.h"
@interface GHTableViewController (){
    NSArray *_files;
    NSArray *_networkfiles;
}

@end

@implementation GHTableViewController

- (void)reloadFiles
{
    // Local files
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    NSLog(@"Document path: %@", docPath);
    
    NSArray *files = [[NSFileManager defaultManager]
                      contentsOfDirectoryAtPath:docPath error:NULL];
    
    NSMutableArray *mediaFiles = [NSMutableArray array];
    for (NSString *f in files) {
        NSString *extname = [[f pathExtension] lowercaseString];
        if ([@[@"avi",@"wmv",@"rmvb",@"flv",@"f4v",@"swf",@"mkv",@"dat",@"vob",@"mts",@"ogg",@"mpg",@"wma",@"mp4",@"mp3"] indexOfObject:extname] != NSNotFound) {
            [mediaFiles addObject:[docPath stringByAppendingPathComponent:f]];
        }
    }
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *moviePath = [mainBundle pathForResource:@"纪念抗日69周年" ofType:@"flv"];
    [mediaFiles addObject:moviePath];
    _files = mediaFiles;
    
    // Network files
    _networkfiles = @[@{@"url":@"rtmp://edge01.fms.dutchview.nl/botr/bunny.flv",@"title":@"rtmp://Bunny.FLV"},
                      @{@"url":@"http://v.youku.com/player/getRealM3U8/vid/XNDY2ODM2NTg0/type/mp4", @"title":@"Youku music video"},
                      @{@"url":@"http://hot.vrs.sohu.com/ipad1407291_4596271359934_4618512.m3u8", @"title":@"Youku m3u8 video"}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self reloadFiles];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FileTableCell"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return _networkfiles.count;
        case 1:
            return _files.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileTableCell" forIndexPath:indexPath];
    NSString *file = nil;
    
    switch (indexPath.section) {
        case 0:
            file = [_networkfiles objectAtIndex:indexPath.row][@"title"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:
            file = [_files objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            break;
    }
    cell.imageView.image=[UIImage imageNamed:@"SBTableCellFileIconVideo"];
    cell.textLabel.text = [file lastPathComponent];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Network streams";
        case 1:
            return @"Local files";
        default:
            return nil;
    }
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    //VLCMovieViewController *detailViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController~ipad" bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    //[self.navigationController pushViewController:detailViewController animated:YES];
    switch (indexPath.section) {
        case 0:
            [self playMediaFileWithURL:[_networkfiles objectAtIndex:indexPath.row][@"url"]];
            //[self playMedia:[_networkfiles objectAtIndex:indexPath.row][@"url"]];
            break;
        case 1:
            [self playMediaFile:[_files objectAtIndex:indexPath.row]];
            //[self playMedia:[_networkfiles objectAtIndex:indexPath.row][@"url"]];
            break;
    }
    
}
- (void)playMediaFile:(NSString *)mediaFile {
    [self playMedia:[NSURL fileURLWithPath:mediaFile]];
}
- (void)playMediaFileWithURL:(NSString *)mediaFile {
    [self playMedia:[NSURL URLWithString:mediaFile]];
}
- (void)playMedia:(NSURL *)mediaURL {
    NSLog(@"mediaURL=%@",mediaURL);
    if([mediaURL isKindOfClass:[NSURL class]]) {
        [self playMedias:[NSArray arrayWithObject:mediaURL]];
    }
}
- (void)playMedias:(NSArray *)mediaURLs {
    [self playMedias:mediaURLs atIndex:0];
}
- (void)playMedias:(NSArray *)mediaURLs atIndex:(NSUInteger)index {
    NSMutableArray *medias = [NSMutableArray arrayWithCapacity:10];
    for (id url in mediaURLs) {
        if([url isKindOfClass:[NSURL class]]) {
            NSURL *mediaURL = url;
            NSString *strExt = [[mediaURL pathExtension] lowercaseString];
            if([mediaURL isFileURL] &&[strExt isEqualToString:@"m3u8"]) {//[FileManager isSystemFileItemM3U8Package:mediaURL.path]
                mediaURL = [NSURL URLWithString:@"index.m3u8" relativeToURL:mediaURL];
            }
            if(mediaURL) {
                SBMediaItem *media = [SBMediaItem itemWithURL:mediaURL];
                [medias addObject:media];
            }
        } else if ([url isKindOfClass:[SBMediaItem class]]) {
            [medias addObject:url];
        }
    }
    self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController" bundle:nil];
    self.movieViewController.playlist = medias;
    //[self.movieViewController playMediaAtIndex:index];
    
    if(self.movieViewController.inMiniTVMode) {
        [self.movieViewController playInMiniTV:nil];
    } else {
        //[self.navigationController pushViewController:self.movieViewController animated:YES];
        [self.navigationController presentViewController:self.movieViewController animated:YES completion:nil];
    }
}
#pragma mark - VLCMovieViewControllerDelegate methods

- (void)moviePlayerWillStart:(VLCMovieViewController *)movieViewController {
    CATransition *animation = [self animationForShowOrHideMovieView:YES];
    
    //UIWindow *window = [ViewUtil applicationMainWindow];
    UIWindow *window=[[UIWindow alloc]init];
    NSArray *windows = [[UIApplication sharedApplication] windows];
    if(windows.count > 0) {
        window=[windows objectAtIndex:0];
    } else {
        window=nil;
    }

    [window.layer addAnimation:animation forKey:@"animation"];
    
    self.movieViewController.view.frame = window.bounds;
}

- (void)moviePlayerDidFinish:(VLCMovieViewController *)movieViewController {
    CATransition *animation = [self animationForShowOrHideMovieView:NO];
    //UIWindow *window = [ViewUtil applicationMainWindow];
    UIWindow *window=[[UIWindow alloc]init];
    NSArray *windows = [[UIApplication sharedApplication] windows];
    if(windows.count > 0) {
        window=[windows objectAtIndex:0];
    } else {
        window=nil;
    }

    [window.layer addAnimation:animation forKey:@"animation"];
    
    [self.movieViewController.view removeFromSuperview];
}
- (CATransition *)animationForShowOrHideMovieView:(BOOL)show {
    NSString *animationSubtype;
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if(show) {
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                animationSubtype = kCATransitionFromTop;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                animationSubtype = kCATransitionFromBottom;
                break;
            case UIDeviceOrientationLandscapeLeft:
                animationSubtype = kCATransitionFromLeft;
                break;
            case UIDeviceOrientationLandscapeRight:
                animationSubtype = kCATransitionFromRight;
                break;
            default:
                animationSubtype = kCATransitionFromTop;
                break;
        }
    } else {
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                animationSubtype = kCATransitionFromBottom;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                animationSubtype = kCATransitionFromTop;
                break;
            case UIDeviceOrientationLandscapeLeft:
                animationSubtype = kCATransitionFromRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                animationSubtype = kCATransitionFromLeft;
                break;
            default:
                animationSubtype = kCATransitionFromBottom;
                break;
        }
    }
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3f;
    animation.fillMode = kCAFillModeForwards;
    animation.type = kCATransitionMoveIn;
    animation.subtype = animationSubtype;
    return animation;
}

@end
