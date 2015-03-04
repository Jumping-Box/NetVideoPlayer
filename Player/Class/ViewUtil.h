//
//  ImageUtil.h
//  ScrollableTabBar
//
//  Created by zongfei zhang on 10-5-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ViewUtil : NSObject {

}

/*
 判断当前设备是否是Retina显示屏
 */
+ (BOOL) isRetinaSupport;

/*
// 指定的视图抓图后返回UIImage的对象。
*/
#pragma mark -
#pragma mark Capture Image methods
+ (UIImage *)capture:(UIView *)viewToCapture;

+ (UIImage *)capture:(UIView *)viewToCapture withRetinaSupport:(BOOL) support;

+ (UIImage *) captureImageFromView:(UIView *)view inRect:(CGRect) rect;

+ (UIImage *) captureImageFromView:(UIView *)view inRect:(CGRect) rect withRetinaSupport:(BOOL)support;

+ (UIImage *)captureAndSaveToAlbum:(UIView *)viewToCapture;

+ (void)saveImageToAlbum:(UIImage *)image;

+ (BOOL)isValidateImage:(UIImage *)image ;

+ (void)captureImage:(UIImage *)image toLocalFile:(NSString *)file;

+ (void)capture:(UIView *)viewToCapture toLocalFile:(NSString *)file ;

+ (void)capture:(UIView *)viewToCapture toLocalFile:(NSString *)file withRetinaSupport:(BOOL) support;

+ (void)captureViewTree:(UIView *)viewTreeToCapture toLocalFile:(NSString *)file;

+ (void)saveImage:(UIImage *)image ToLocalFile:(NSString *)file;

/*
 抓取浏览器头部视图作为当前skin的缩略图，并使用给定的名称保存到应用的tmp目录下
 */
+ (void) captureSkinThumbnails:(UIView *)headerView saveToTmp:(NSString *)saveName;

+ (void)captureImageForLaunching;

#pragma mark -
#pragma mark UITableView util methods

+ (NSIndexPath *)getIndexPathForTableView:(UITableView *)tableView event:(id)event;

+ (NSMutableArray *)getIndexPathsTableViewController:(UITableViewController *)vc;

+ (NSInteger)getIndexPathOffset:(NSIndexPath *)indexPath in:(UITableViewController *)vc;

#pragma mark -
#pragma mark Image Effect methods

+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage;

+ (UIImage *)blendImage:(UIImage *)backgroundImage withImage: (UIImage *)forgroundImage mode:(CGBlendMode)blendMode ;

+ (UIImage *)maskImage:(UIImage *)image withImage:(UIImage *)maskImage;

+ (UIImage *)addAppIconEffect:(UIImage *)image;

+ (UIImage *)change:(UIImage *)image toSize:(CGSize )size;

+ (UIImage *)scale:(UIImage *)image toSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/*
 等比缩放
 */
+ (UIImage*) geometricScaleImage:(UIImage *)image ToSize:(CGSize)size;

/*
 * 将图片按照当前设备处理成对应尺寸的圆角icon
 */
+ (UIImage *)getRoundCornerIconWithImage:(UIImage *)aImage ;

/*
 * 可将网站的Favicon图片外添加一个圆环，处理成图标的样式，圆环的颜色为图标的平均色（Favicon平均取色待实现）。
 */
+ (UIImage *)getIconImageWithFaviconImage:(UIImage *)image;
#pragma mark -
#pragma mark Core Web View methods

+ (id)coreWebView:(UIWebView *)webView;
+ (id)backForwardList:(UIWebView *)webView;
+ (NSInteger)countOfBackList:(id)backForwardList ;
+ (NSInteger)countOfForwardList:(id)backForwardList;

+ (id)historyItemWithUrl:(NSString *)url title:(NSString *)title lastVisitedTimeInterval:(NSTimeInterval)timeInterval;
+ (void)addHistoryItem:(id)item toWebView:(UIWebView *)webView;
+ (id)historyItemAtIndex:(NSInteger)index forBackForwardList:(id)backForwardList;
+ (NSString *)titleForHistoryItem:(id)historyItem ;
+ (NSString *)urlStringForHistoryItem:(id)historyItem ;
+ (int)lastVisitedTimeIntervalForHistoryItem:(id)historyItem;
+ (void)backForwardList:(id)backForwardList goToItem:(id)item;

+ (id)mainFrameForWebView:(UIWebView *)webView;
+ (NSURL *)urlForWebFrame:(id)webFrame;
+ (id)dataSourceForFrame:(id)frame;

+ (void)webView:(UIWebView *)webView loadWebArchive:(id)webArchive;
+ (NSData *)getWebArchiveData:(UIWebView *)webView;
+ (id)webArchiveForDataSource:(id)dataSource ;
+ (id)webArchiveWithData:(NSData *)data ;

+ (UIScrollView *)scrollViewForWebView:(UIWebView *)webView;
+ (UIView *)browserViewForWebView:(UIWebView *)webView;
+ (double)estimatedProgressForWebView:(UIWebView *)webView;

#pragma mark - WebView Delegate Methods

+ (id)policyDelegateForWebView:(UIWebView *)webView;
+ (id)uiDelegateFowWebView:(UIWebView *)webView;
+ (id)frameDelegateForWebView:(UIWebView *)webView;
+ (void)webview:(UIWebView *)webView setThunderDelegate:(id)downloadDelegate;
+ (void)webView:(UIWebView *)webView setFrameDelegate:(id)frameDelegate;

#pragma mark - User Agent Methods
+ (NSString *)userAgentForWebView:(UIWebView *)webView;
+ (void)setUserAgent:(NSString *)userAgent ForWebView:(UIWebView *)webView;

#pragma mark - WebView Preference Methods

+ (id)sharedWebViewPreference;
+ (id)webPreferenceFowWebView:(UIWebView *)webView;
+ (BOOL)isSupportPrivateBrowsingMode;
+ (void)setPrivateBrowsingModeEnabled:(BOOL)enabled;
+ (BOOL)isPrivateBrowsingModeEnabled;
+ (void)setAllowPopups:(BOOL)allow;
+ (BOOL)isAllowPopups;

#pragma mark -
#pragma mark Private API methods

+ (SEL)generate:(NSArray *)array;
+ (Class)generateClass:(NSArray *)array;

#pragma mark -
#pragma mark other methods

+ (void)bringViewChainToFront:(UIView *)view ;

+ (void)printViewTree:(UIView *)view level:(NSInteger)level depth:(NSInteger)depth;

+ (void)printViewTree:(UIView *)view ; // 控制台输出视图层次，效果与控制台打断点后的 po [view recursiveDescription ]方法 一致

+ (UIView *)getFirstParentView:(UIView *)view ofKind:(Class)clazz;

+ (UIView *)getFirstViewFromViewTree:(UIView *)view ofKind:(Class)clazz;

+ (void)applyUniformGradientViewTo:(UIView *) destview from:(UIColor *) startColor to:(UIColor *) endColor;

+ (UIView *)rootView;

+ (UIWindow *)applicationMainWindow;

+ (UIResponder *)applicationCurrentFirstResponder;

+ (UIResponder *)currentFirstResponderInView:(UIView *)parentView;

+ (UIViewController *)rootViewController;

+ (UIViewController *)topMostViewController;

//+ (void)topMostViewControllerPresentViewController:(UIViewController *)willBePresentingViewController animated: (BOOL)flag completion:(void (^)(void))completion;
//
///* 安全地弹出模态视图，可以避免出现一个模态视图正在弹出的时候又去弹出另外的模态视图引起的崩溃问题 */
//+ (void)viewController:(UIViewController *)parentViewController safelyPresentViewController:(UIViewController *)presentViewController animated:(BOOL)flag completion:(void (^)(void))completion;

+ (void)adjustTopViewSize;

+ (UIBarButtonItem *)hideBarButtonItem: (UIViewController *)viewController ;

+ (CGFloat)verticalDistanceFromView:(UIView *)a toView:(UIView *)b;

+ (UIWindow *)topMostWindow;

/**
 * 判断给定的UIViewController对象是否是present出来的
 */
+ (BOOL)isPresentedViewController:(UIViewController *)viewController;

/**
 * 校正给定的viewController屏幕方向，如果viewController为nil，则默认校正本应用的rootViewController
 */
+ (void)correctOrientation:(UIViewController *)viewController;

/*
// 从View Tree中获得其所有的Gesture Recognizers.
*/
+ (NSMutableArray *)getGestureRecognizers:(UIView *)view;

+ (UIColor *)colorFromRgbValue:(NSNumber *)rgbValue;

+ (void)splitViewController:(UISplitViewController *)splitViewController hideMasterView:(BOOL)hide;


//提供一个方法显示半透明模态提示信息，在delay 秒后消失，内部使用MBprogress实现
+ (void)showRemindText:(NSString *)text disappearAfterDelay:(float)delay ;

@end
