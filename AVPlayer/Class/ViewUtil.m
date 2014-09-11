//
//  ImageUtil.m
//  ScrollableTabBar
//
//  Created by zongfei zhang on 10-5-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ViewUtil.h"

#define APP_ICON_MASK_IMAGE @"AppIconMask_29.png"
#define APP_ICON_OVERLAY_IMAGE @"AppIconOverlay_29.png"

@implementation ViewUtil

+ (BOOL) isRetinaSupport {
    BOOL support = NO;
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        CGFloat scale = [[UIScreen mainScreen] scale];
        if (scale > 1.0) {
            support = YES;
        }
    }
    return support;
}

+ (UIImage *)capture:(UIView *)viewToCapture {
	return [ViewUtil capture:viewToCapture withRetinaSupport:YES];
	
}

+ (UIImage *)capture:(UIView *)viewToCapture withRetinaSupport:(BOOL) support {
    CGRect bounds = viewToCapture.bounds;
    //支持retina高分的关键
    if(support && UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(bounds.size, viewToCapture.opaque, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(bounds.size);
    }
    //UIGraphicsBeginImageContext(bounds.size);
    [viewToCapture.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *) captureImageFromView:(UIView *)view inRect:(CGRect) rect withRetinaSupport:(BOOL)support {
    UIImage *tempImage = [ViewUtil capture:view withRetinaSupport:support];
    CGImageRef cgImage = CGImageCreateWithImageInRect([tempImage CGImage], rect);
    UIImage *theNewImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return theNewImage;
}

+ (UIImage *) captureImageFromView:(UIView *)view inRect:(CGRect) rect {
    return [ViewUtil captureImageFromView:view inRect:rect withRetinaSupport:YES];
}

+ (UIImage *)captureAndSaveToAlbum:(UIView *)viewToCapture {
	UIImage *image = [ViewUtil capture:viewToCapture];
	UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	return image;
}

+ (void)saveImageToAlbum:(UIImage *)image {
	UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}


+ (BOOL)isValidateImage:(UIImage *)image {
	BOOL result = NO;
	if (image!=nil && image.size.width >0 && image.size.height >0) {
		result = YES;
	}
	return result;
}

+ (void)captureImage:(UIImage *)image toLocalFile:(NSString *)file {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	[ViewUtil capture:imageView toLocalFile:file];
}


+ (void)capture:(UIView *)viewToCapture toLocalFile:(NSString *)file {
	[ViewUtil capture:viewToCapture toLocalFile:file withRetinaSupport:NO];
}

+ (void)capture:(UIView *)viewToCapture toLocalFile:(NSString *)file withRetinaSupport:(BOOL) support {
	UIImage *image = [ViewUtil capture:viewToCapture withRetinaSupport:support];
#ifdef DEBUG
    NSLog(@"image's size = %@", NSStringFromCGSize(image.size));
#endif
	[ViewUtil saveImage:image ToLocalFile:file];
}

+ (void)captureViewTree:(UIView *)viewTreeToCapture toLocalFile:(NSString *)file {
    [ViewUtil capture:viewTreeToCapture toLocalFile:file withRetinaSupport:YES];
    NSArray *subviews = viewTreeToCapture.subviews;
    for(UIView *view in subviews) {
        NSString *filePathWithoutExt = [file stringByDeletingPathExtension];
        NSString *fileExtention = [file pathExtension];
        NSString *additionSubViewFileName = [NSString stringWithFormat:@"%@-%i.%@", [[view class] description], [view hash], fileExtention];
        NSString *subviewFileName = [filePathWithoutExt stringByAppendingPathExtension:additionSubViewFileName];
        [ViewUtil captureViewTree:view toLocalFile:subviewFileName];
    }
}

#pragma mark -
#pragma mark UITableView util methods

+ (NSIndexPath *)getIndexPathForTableView:(UITableView *)tableView event:(id)event {
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:tableView];
	
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint: currentTouchPosition];
	
	return indexPath;
}

+ (NSMutableArray *)getIndexPathsTableViewController:(UITableViewController *)vc {
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (NSInteger section = 0; section < [vc numberOfSectionsInTableView:vc.tableView] ; section ++) {
		for (NSInteger row=0; row < [vc tableView:vc.tableView numberOfRowsInSection:section]; row++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
			[indexPaths addObject:indexPath];
		}
	}
	return indexPaths;
}

+ (NSInteger)getIndexPathOffset:(NSIndexPath *)indexPath in:(UITableViewController *)vc {
	NSInteger offset = 0;
	NSInteger section = indexPath.section;
	for (NSInteger i = 0; i < section ; i++) {
		offset += [vc tableView:vc.tableView numberOfRowsInSection:i];
	}
	
	offset += indexPath.row;
	return offset;
}


#pragma mark -
#pragma mark App Icon Effect methods

+ (UIImage *)blendImage:(UIImage *)backgroundImage withImage: (UIImage *)forgroundImage mode:(CGBlendMode)blendMode {
	UIGraphicsBeginImageContext(forgroundImage.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGRect rect = {0, 0, forgroundImage.size.width, forgroundImage.size.height};
	CGContextTranslateCTM(context, 0, rect.size.height);
	CGContextScaleCTM(context, 1, -1);
	
	
	CGContextDrawImage(context, rect, backgroundImage.CGImage);
	CGContextSetBlendMode(context, kCGBlendModeOverlay);
	CGContextDrawImage(context, rect, forgroundImage.CGImage);
	
	UIImage *blendedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	
	return blendedImage;
}

+ (UIImage *)maskImage:(UIImage *)image withImage:(UIImage *)maskImage {
	UIGraphicsBeginImageContext(image.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGRect rect = {0, 0, image.size.width, image.size.height};
	
	CGContextClipToMask(context, rect, maskImage.CGImage);
	[image drawInRect:rect];
	
	UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	
	return maskedImage;
}


+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
	
	CGImageRef maskRef = maskImage.CGImage;
	
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
										CGImageGetHeight(maskRef),
										CGImageGetBitsPerComponent(maskRef),
										CGImageGetBitsPerPixel(maskRef),
										CGImageGetBytesPerRow(maskRef),
										CGImageGetDataProvider(maskRef), NULL, false);
	
	CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
	CGImageRelease(mask);
    
	UIImage *result = [UIImage imageWithCGImage:masked];
	CGImageRelease(masked);
    
	return result;
}

+ (UIImage *)change:(UIImage *)image toSize:(CGSize )size {
	UIGraphicsBeginImageContext(size);
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	[image drawInRect:rect];
	
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return result;
}

+ (UIImage *)scale:(UIImage *)image toSize:(CGSize)size contentMode:(UIViewContentMode)contentMode {
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width,size.height)];
	imageView.contentMode = contentMode;
	imageView.image = image;
	
	UIImage *result = [ViewUtil capture:imageView];
    
	return result;
}

+ (UIImage*) geometricScaleImage:(UIImage *)image ToSize:(CGSize)size
{
    //如果给定的图片尺寸已经是要缩放的尺寸，则无需缩放，直接返回原图片
    if(CGSizeEqualToSize(image.size, size)) return image;
    
	CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
	
	float verticalRadio = size.height*1.0/height;
	float horizontalRadio = size.width*1.0/width;
	
	float radio = 1;
	if(verticalRadio>1 && horizontalRadio>1)
	{
		radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
	}
	else
	{
		radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
	}
	
	width = width*radio;
	height = height*radio;
	
	int xPos = (size.width - width)/2;
	int yPos = (size.height-height)/2;
	
	// 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
	//支持retina高分的关键
    if(UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(xPos, yPos, width, height)];
	
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
	
    // 返回新的改变大小后的图片
    return scaledImage;
}

+ (UIImage *)getRoundCornerIconWithImage:(UIImage *)aImage{
    //  更精细的处理  http://www.mani.de/backstage/?p=483
    CGFloat nSize ;
    CGFloat nCornerRadius;
    BOOL isOverIOS7 =  SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
    BOOL isIpad =  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    if (isOverIOS7) {
        nSize = isIpad ? 76 : 60 ;
        nCornerRadius = isIpad ? 13.5 : 10.5 ;
    }else{
        nSize = isIpad ? 72 : 57 ;
        nCornerRadius = isIpad ? 11.5 : 9 ;
    }
    
    UIImageView *imgaeView =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, nSize, nSize)];
    imgaeView.image = aImage ;
    imgaeView.layer.cornerRadius = nCornerRadius ;
    imgaeView.layer.masksToBounds = YES;
    return [ViewUtil capture:imgaeView withRetinaSupport:YES];
}

+ (UIImage *)getIconImageWithFaviconImage:(UIImage *)image{
//    UIColor *color =[image averageColor];
    //取平均色待实现
    UIColor *color = [UIColor redColor];
    
    CGRect rect ;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        rect = CGRectMake(0, 0, 57, 57);
    }else{
        rect = CGRectMake(0, 0, 72, 72);
    }
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextAddArc(context, rect.size.width/2  , rect.size.height/2, rect.size.width/2.0 - 1.0, 0, 2*M_PI, 0);
    CGContextDrawPath(context, kCGPathStroke);
    
    
    CGPoint center = CGPointMake(rect.origin.x + rect.size.width/2.0, rect.origin.y + rect.size.height/2.0);
    //在中心，绘制16*16的favicon
    CGRect rectNew =  CGRectMake(center.x -8, center.y- 8, 16, 16);
    [image drawInRect:rectNew];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

#pragma mark -
#pragma mark Core Web View methods

+ (id)coreWebView:(UIWebView *)webView {
	id coreWebView = nil;
	
	SEL sel = [ViewUtil generate:[NSArray arrayWithObjects:@"_",
                                  @"temp01",
                                  @"document",
                                  @"temp02",
                                  @"View",
                                  @"temp03",
                                  nil]];
	
	if ([webView respondsToSelector:sel]) {
        coreWebView = [[webView performSelector:sel] performSelector:@selector(webView)];
	}
	return coreWebView;
}

+ (id)backForwardList:(UIWebView *)webView {
    id coreWebView =  [ViewUtil coreWebView:webView];
    id backForwardList = nil;
    
    SEL sel = [ViewUtil generate:[NSArray arrayWithObjects:@"backForward",@"temp1",@"List",@"temp2", nil]];
    if ([coreWebView respondsToSelector:sel]) {
        backForwardList = [coreWebView performSelector:sel];
    }
    
    return backForwardList;
}

+ (NSInteger)countOfBackList:(id)backForwardList {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"backList", @"temp",@"Count",@"temp",nil]];
    NSInteger count = (NSInteger)[LangUtil target:backForwardList performSelector:selector withObjects:nil hasRawReturnValue:YES];
    return count;
}


+ (id)historyItemWithUrl:(NSString *)url title:(NSString *)title lastVisitedTimeInterval:(NSTimeInterval)timeInterval{
    Class webHistoryItemClass =  [ViewUtil generateClass:[NSArray arrayWithObjects:@"Web",@"temp1",
                                                          @"History",@"temp2",@"Item",@"temp3",
                                                          nil]];
    id item = [webHistoryItemClass alloc] ;
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"initWithURLString:",@"temp",@"title:",@"temp",@"lastVisitedTimeInterval:",@"temp", nil]];
    item = [LangUtil target:item performSelector:selector withObjects:[NSArray arrayWithObjects:url,title,[NSNumber numberWithDouble:timeInterval] , nil] hasReturnValue:YES];
    
    return item;
}

+ (id)historyItemAtIndex:(NSInteger)index forBackForwardList:(id)backForwardList {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"item",@"temp",@"At",@"temp",@"Index:",@"temp", nil]];
    id item = [LangUtil target:backForwardList performSelector:selector  withObjects:[NSArray arrayWithObject:[NSNumber numberWithInteger:index]] hasReturnValue:YES];
    return item;
}

+ (void)addHistoryItem:(id)item toWebView:(UIWebView *)webView{
    id backForwardList = [ViewUtil backForwardList:webView];
    
    SEL sel = [ViewUtil generate:[NSArray arrayWithObjects:@"add",@"temp",@"Item:",@"temp", nil]];
    if ([backForwardList respondsToSelector:sel]) {
        [backForwardList performSelector:sel withObject:item];
    }
}

+ (NSString *)titleForHistoryItem:(id)historyItem {
    NSString *title = [LangUtil target:historyItem performSelector:@selector(title) withObjects:nil hasReturnValue:YES];
    return title;
}

+ (NSString *)urlStringForHistoryItem:(id)historyItem {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"URL",@"temp",@"String",@"temp", nil]];
    NSString *urlString = [LangUtil target:historyItem performSelector:selector withObjects:nil hasReturnValue:YES];
    return urlString;
}

+ (int)lastVisitedTimeIntervalForHistoryItem:(id)historyItem {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"lastVisited",@"temp",@"TimeInterval",@"temp", nil]];
    int timeInterval = (int)[historyItem performSelector:selector];
    return timeInterval;
}

+ (void)backForwardList:(id)backForwardList goToItem:(id)item {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"goTo",@"temp",@"Item:",@"temp", nil]];
    [LangUtil target:backForwardList performSelector:selector withObjects:[NSArray arrayWithObject:item] hasReturnValue:NO];
}



+ (void)webView:(UIWebView *)webView loadWebArchive:(id)webArchive {
    id mainFrame = [ViewUtil mainFrameForWebView:webView];
    SEL loadArchiveSelector = [ViewUtil generate:[NSArray arrayWithObjects:@"load",@"temp",@"Archive:",@"temp", nil]];
    
    BOOL isValidateWebArchive = NO;
    NSString *message = nil;
    
    @try {
        NSData *data = [LangUtil target:webArchive performSelector:@selector(data) withObjects:nil hasReturnValue:YES];
        if (data) {
            //当且仅当Web Archive的数据有效时，加载此Web Archivie.
            [LangUtil target:mainFrame performSelector:loadArchiveSelector withObjects:[NSArray arrayWithObject:webArchive] hasReturnValue:NO];
            isValidateWebArchive = YES;
        }
    }@catch (NSException *exception) {
        message = [exception reason];
    }
    
    if (!isValidateWebArchive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Invalid Web Archive", SB_MESSAGE_FILE,@"无效的Web页面") message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:MESSAGE_CLOSE, nil];
        [alertView show];
    }
    
}

+ (id)mainFrameForWebView:(UIWebView *)webView{
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL mainFrameSelector = [ViewUtil generate:[NSArray arrayWithObjects:@"main", @"temp",@"Frame",@"temp",nil]];
    id mainFrame = [LangUtil target:coreWebView performSelector:mainFrameSelector withObjects:nil hasReturnValue:YES];
    return mainFrame;
}

+ (NSURL *)urlForWebFrame:(id)webFrame {
	NSURL *url = nil;
	if ([webFrame respondsToSelector:@selector(dataSource)]) {
		id dataSource = [webFrame performSelector:@selector(dataSource)];
		if ([dataSource respondsToSelector:@selector(request)]) {
			id request = [dataSource performSelector:@selector(request)];
			if ([request respondsToSelector:@selector(URL)]) {
				url = [request performSelector:@selector(URL)];
			}
		}
	}
	return url;
}

+ (id)dataSourceForFrame:(id)frame {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"data",@"temp",@"Source",@"temp", nil]];
    id dataSource = [LangUtil target:frame performSelector:selector withObjects:nil hasReturnValue:YES];
    return  dataSource;
}

+ (id)webArchiveForDataSource:(id)dataSource {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"web",@"temp",@"Archive",@"temp", nil]];
    id webArchive = [LangUtil target:dataSource performSelector:selector withObjects:nil hasReturnValue:YES];
    return webArchive;
}


+ (NSData *)getWebArchiveData:(UIWebView *)webView {
	id mainFrame = [ViewUtil mainFrameForWebView:webView];
	id dataSource = [ViewUtil dataSourceForFrame:mainFrame];
	id webArchive = [ViewUtil webArchiveForDataSource:dataSource];
    
	NSData *data = nil;
    NSString *url = [webView.request.URL absoluteString];
    if ([url length] > 0) {
        data = [LangUtil target:webArchive performSelectorWithReturnValue:@selector(data)];
    }
    return  data;
}

+ (id)webArchiveWithData:(NSData *)data {
    Class webArchiveClass = [ViewUtil generateClass:[NSArray arrayWithObjects:@"Web",@"temp",@"Archive",@"temp", nil]];
    id archive = [webArchiveClass alloc];
    archive = [LangUtil target:archive performSelector:@selector(initWithData:) withObjects:[NSArray arrayWithObject:data] hasReturnValue:YES];
    return archive ;
}

+ (UIScrollView *)scrollViewForWebView:(UIWebView *)webView {
    UIScrollView* scrollerView = (UIScrollView *)[ViewUtil getFirstViewFromViewTree:webView ofKind:NSClassFromString(@"UIScrollView")];
    return scrollerView;
}

+ (UIView *)browserViewForWebView:(UIWebView *)webView{
    Class clazz = [ViewUtil generateClass:[NSArray arrayWithObjects:@"UIWeb",@"temp",@"BrowserView",@"temp", nil]];
    UIView* docView = [ViewUtil getFirstViewFromViewTree:webView ofKind:clazz];
    return docView;
}

+ (double)estimatedProgressForWebView:(UIWebView *)webView {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"estimated",@"temp",@"Progress",@"temp", nil]];
    id coreWebView = [ViewUtil coreWebView:webView];
    IMP myImp = [coreWebView methodForSelector:selector];
    double webViewProgress = ( (double (*) (id,SEL))myImp)(coreWebView,selector);
    return webViewProgress;
}

+ (id)policyDelegateForWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"policy",
                                   @"temp12",
                                   @"Delegate",
                                   @"temp13",
                                   nil]];
    return [LangUtil target:coreWebView performSelector:sel withObjects:nil hasReturnValue:YES];
}

+ (id)uiDelegateFowWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"UI",
                                   @"temp12",
                                   @"Delegate",
                                   @"temp13",
                                   nil]];
    return [LangUtil target:coreWebView performSelector:sel withObjects:nil hasReturnValue:YES];
}

+ (id)frameDelegateForWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"frameLoad",
                                   @"temp12",
                                   @"Delegate",
                                   @"temp13",
                                   nil]];
    return [LangUtil target:coreWebView performSelector:sel withObjects:nil hasReturnValue:YES];
}

+ (void)webview:(UIWebView *)webView setThunderDelegate:(id)downloadDelegate {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"setDownload",
                                   @"temp12",
                                   @"Delegate:",
                                   @"temp13",
                                   nil]];
    [LangUtil target:coreWebView performSelector:sel withObjects:[NSArray arrayWithObject:downloadDelegate] hasReturnValue:NO];
}

+ (void)webView:(UIWebView *)webView setFrameDelegate:(id)frameDelegate{
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray  arrayWithObjects:
                                   @"set",
                                   @"temp21",
                                   @"Frame",
                                   @"temp22",
                                   @"Load",
                                   @"temp23",
                                   @"Delegate",
                                   @"temp24",
                                   @":",
                                   nil]];
    [LangUtil target:coreWebView performSelector:sel withObjects:[NSArray arrayWithObject:frameDelegate] hasReturnValue:NO];
}


+ (NSString *)userAgentForWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"custom",
                                   @"temp12",
                                   @"UserAgent",
                                   @"temp13",
                                   nil]];
    return [LangUtil target:coreWebView performSelector:sel withObjects:nil hasReturnValue:YES];
}

+ (void)setUserAgent:(NSString *)userAgent ForWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL sel = [ViewUtil generate: [NSArray arrayWithObjects:
                                   @"set",
                                   @"temp11",
                                   @"Custom",
                                   @"temp12",
                                   @"UserAgent:",
                                   @"temp13",
                                   nil]];
    id userAgentObj = userAgent;
    if (userAgentObj == nil) {
        userAgentObj = [NSNull null];
    }
    
    [LangUtil target:coreWebView performSelector:sel withObjects:[NSArray arrayWithObject:userAgentObj] hasReturnValue:NO];
}

#pragma mark - WebView Preference Methods

+ (id)sharedWebViewPreference{
    Class webPreferenceClass = [ViewUtil generateClass:[NSArray arrayWithObjects:@"Web",@"t",@"Preferences",@"t",nil]];
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"standard",@"t",@"Preferences",@"t", nil]];
    
    id webPrefernce = [LangUtil target:webPreferenceClass performSelector:selector withObjects:nil hasReturnValue:YES];
    return webPrefernce;
}

+ (id)webPreferenceFowWebView:(UIWebView *)webView {
    id coreWebView = [ViewUtil coreWebView:webView];
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"prefer",@"t",@"ences",@"t", nil]];
    
    id webPrefernce = [LangUtil target:coreWebView performSelector:selector withObjects:nil hasReturnValue:YES];
    return webPrefernce;
}

+ (BOOL)isSupportPrivateBrowsingMode {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"private",@"t",@"BrowsingEnabled",@"t", nil]];
    id webPreference = [ViewUtil sharedWebViewPreference];
    return [webPreference respondsToSelector:selector];
}

+ (void)setPrivateBrowsingModeEnabled:(BOOL)enabled {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"setPrivate",@"t",@"BrowsingEnabled:",@"t", nil]];
    id webPreference = [ViewUtil sharedWebViewPreference];
    [LangUtil target:webPreference performSelector:selector withObjects:[NSArray arrayWithObject:[NSNumber numberWithBool:enabled]] hasReturnValue:NO];
}

+ (BOOL)isPrivateBrowsingModeEnabled {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"private",@"t",@"BrowsingEnabled",@"t", nil]];
    id webPreference = [ViewUtil sharedWebViewPreference];
    
    BOOL result = NO;
    if ([webPreference respondsToSelector:selector]) {
        IMP myImp = [webPreference methodForSelector:selector];
        result = ( (BOOL (*) (id,SEL))myImp)(webPreference,selector);
    }
    
    return result;
}

+ (void)setAllowPopups:(BOOL)allow {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"setJavaScript",@"t",@"CanOpenWindowsAutomatically:",@"t", nil]];
    id webPreference = [ViewUtil sharedWebViewPreference];
    [LangUtil target:webPreference performSelector:selector withObjects:[NSArray arrayWithObject:[NSNumber numberWithBool:allow]] hasReturnValue:NO];
}

+ (BOOL)isAllowPopups {
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"javaScript",@"t",@"CanOpenWindowsAutomatically",@"t", nil]];
    id webPreference = [ViewUtil sharedWebViewPreference];
    
    BOOL result = YES;
    if ([webPreference respondsToSelector:selector]) {
        IMP myImp = [webPreference methodForSelector:selector];
        result = ( (BOOL (*) (id,SEL))myImp)(webPreference,selector);
    }
    
    return result;
}


#pragma mark -
#pragma mark Private API methods

+ (SEL)generate:(NSArray *)array {
	//只取单数。
	NSMutableString *s = [NSMutableString stringWithString:@""];
	for (int i = 0; i < [array count]; i++) {
		if (i % 2 == 0) {
			[s appendString:[array objectAtIndex:i]];
		}
	}
	
	SEL sel = NSSelectorFromString(s);
	return sel;
}

+ (Class )generateClass:(NSArray *)array {
    //只取单数。
	NSMutableString *s = [NSMutableString stringWithString:@""];
	for (int i = 0; i < [array count]; i++) {
		if (i % 2 == 0) {
			[s appendString:[array objectAtIndex:i]];
		}
	}
    
    Class clazz = NSClassFromString(s);
    return clazz;
}


#pragma mark -
#pragma mark other util methods

+ (void)bringViewChainToFront:(UIView *)view {
	UIView *superView = view.superview;
	UIView *currentView = view;
	while (superView!=nil && currentView != [ViewUtil rootViewController].view) {
        if (superView == [ViewUtil rootViewController].view && [[ViewUtil rootViewController] isKindOfClass:[UITabBarController class]]) {
            break;
        }
		[superView bringSubviewToFront:currentView];
		currentView = superView;
		superView = currentView.superview;
	}
}

+ (void)printViewTree:(UIView *)view level:(NSInteger)level depth:(NSInteger)depth {
	if (level<=depth) {
//		NSString *tab = @"";
//		for (int i = 0; i < level; i++) {
//			tab = [tab stringByAppendingString:@"  "];
//		}
//		NSLog(@"%@%@",tab,view);
//		for (UIWebView *subView in view.subviews) {
//			[ViewUtil printViewTree:subView level:level+1 depth:depth];
//		}
        
       	}
    NSMutableString *outstring = [[ NSMutableString  alloc ]  init];
    [ViewUtil dumpView:view level:level into:outstring  depth:depth];
    
    NSLog(@"%@",outstring);
}

+ (void )dumpView:(UIView  *)aView level:(NSInteger )level into:(NSMutableString  *)outstring depth:(NSInteger)depth
{
    if (level <= depth) {
        for  (int  i = 0 ; i < level; i++){
            [outstring appendString :@"  |" ];
        }
        [outstring appendFormat :@"%@\n" , aView];
        for  (UIView  *view in  [aView subviews ]){
            [self  dumpView :view level :level + 1  into :outstring depth:depth];
        }
    }
}

+ (void)printViewTree:(UIView *)view{
    [ViewUtil printViewTree:view level:0 depth:INT_MAX];
}

+ (UIView *)getFirstParentView:(UIView *)view ofKind:(Class)clazz {
	UIView *result = nil;
	UIView *parentView = view.superview;
	[view class];
	while (parentView) {
		if ([parentView isKindOfClass:clazz]) {
			result = parentView;
			break;
		}else {
			parentView = parentView.superview;
		}
	}
	return result;
}

+ (UIView *)getFirstViewFromViewTree:(UIView *)view ofKind:(Class)clazz {
	UIView *result = nil;
	
	if ([view isKindOfClass:clazz]) {
		result = view;
	}else {
		for (UIView *subView in view.subviews) {
			result = [ViewUtil getFirstViewFromViewTree:subView ofKind:clazz];
			if (result) {
				break;
			}
		}
	}
	
	return result;
}

+ (void) applyUniformGradientViewTo:(UIView *) destview from:(UIColor *) startColor to:(UIColor *) endColor {
	//UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, destview.frame.size.width,destview.frame.size.height)] autorelease];
    //	view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    //	CAGradientLayer *gradient = [CAGradientLayer layer];
    //	gradient.frame = view.bounds;
    //	gradient.colors = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];
    //	[view.layer insertSublayer:gradient atIndex:0];
    //	[destview addSubview:view];
    //	[destview sendSubviewToBack: view];
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = destview.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];
	[destview.layer insertSublayer:gradient atIndex:0];
}

+ (UIView *)rootView {
//    return [UIApplication sharedApplication].keyWindow.rootViewController.view;
     // 上面的方法会导致有些情况下 actionsheet的showInView：传入此view时 view = nil引起的崩溃，传入下面的的view不会出现nil
    return  [ViewUtil topMostViewController].view;
}

+ (UIWindow *)applicationMainWindow {
    //    UIWindow *mainWindow = nil;
    //    NSArray *windows = [UIApplication sharedApplication].windows;
    //    for(UIWindow *window in windows) {
    //        if(window.rootViewController) {
    //            mainWindow = window;
    //            break;
    //        }
    //    }
    //    return mainWindow;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    if(windows.count > 0) {
        return [windows objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (UIResponder *)applicationCurrentFirstResponder {
    UIResponder *firstResponder = nil;
    UIViewController *topMostController = [ViewUtil topMostViewController];
    if([topMostController isFirstResponder]) {
        firstResponder = topMostController;
    } else {
        firstResponder = [ViewUtil currentFirstResponderInView:topMostController.view];
    }
    return firstResponder;
}

+ (UIResponder *)currentFirstResponderInView:(UIView *)parentView {
    UIResponder *firstResponder = nil;
    if([parentView isFirstResponder]) {
        firstResponder = parentView;
    } else {
        NSArray *subviews = [parentView subviews];
        for(UIView *v in subviews) {
            if([v isFirstResponder]) {
                firstResponder = v;
                break;
            } else {
                firstResponder = [ViewUtil currentFirstResponderInView:v];
            }
        }
    }
    return firstResponder;
}

+ (UIViewController *)rootViewController {
    return [[ViewUtil applicationMainWindow] rootViewController];
    //return [UIApplication sharedApplication].keyWindow.rootViewController;
    //    SBBaseAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    //	return appDelegate.rootViewController;
}


+ (UIViewController *)topMostViewController {
    UIViewController *rootVc = [ViewUtil rootViewController];
    UIViewController *modalVc = rootVc;
    
    while (modalVc.modalViewController!=nil) {
        modalVc = modalVc.modalViewController;
    }
    
    return modalVc;
}

//+ (void)topMostViewControllerPresentViewController:(UIViewController *)willBePresentingViewController animated: (BOOL)flag completion:(void (^)(void))completion {
//    UIViewController *topMostViewController = [ViewUtil topMostViewController];
//    [ViewUtil viewController:topMostViewController safelyPresentViewController:willBePresentingViewController animated:flag completion:completion];
//}
//
//+ (void)viewController:(UIViewController *)parentViewController safelyPresentViewController:(UIViewController *)presentViewController animated:(BOOL)flag completion:(void (^)(void))completion {
//    @try {
//        [parentViewController presentViewController:presentViewController animated:flag completion:completion];
//    }
//    @catch (NSException *exception) {
//        /*!
//         捕获这样的异常：
//         Attempting to begin a modal transition from <UIViewController: 0x1c3ee0d0> to <UIViewController: 0x1c48c6c0> while a transition is already in progress. Wait for viewDidAppear/viewDidDisappear to know the current transition has completed
//         */
//        if ([NSInternalInconsistencyException isEqualToString:exception.name]) {
//            double delayInSeconds = 0.01;
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                [ViewUtil viewController:parentViewController safelyPresentViewController:presentViewController animated:flag completion:completion];
//            });
//        } else {
//            SBDebugLog(@"Uncatched exception:%@", exception);
//        }
//    }
//}


+ (void)adjustTopViewSize {
    UIViewController *topMostViewController = [ViewUtil topMostViewController];
    UIInterfaceOrientation orientation = topMostViewController.interfaceOrientation;
    CGFloat statusBarHeight = 20;
    UIView *rootView = topMostViewController.view;
    CGRect windowBounds = [UIApplication sharedApplication].keyWindow.bounds;
    CGRect rootViewRect;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rootViewRect = CGRectMake(0, statusBarHeight, windowBounds.size.width , windowBounds.size.height- statusBarHeight);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rootViewRect = CGRectMake(0, 0, windowBounds.size.width, windowBounds.size.height-statusBarHeight);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rootViewRect = CGRectMake(statusBarHeight, 0, windowBounds.size.width-statusBarHeight, windowBounds.size.height);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rootViewRect = CGRectMake(0, 0, windowBounds.size.width - statusBarHeight, windowBounds.size.height);
            break;
        default:
            break;
    }
    
    rootView.frame = rootViewRect;
}

+ (UIBarButtonItem *)hideBarButtonItem: (UIViewController *)viewController {
	UIBarButtonItem * __autoreleasing hideBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:MESSAGE_HIDE style:UIBarButtonItemStyleDone target:viewController action:@selector(hideButtonTouched:)] ;
	return hideBarButtonItem;
}


+ (CGFloat)verticalDistanceFromView:(UIView *)a toView:(UIView *)b {
    UIView *rootView = [ViewUtil rootViewController].view;
    CGFloat distanceY = [a.superview convertPoint:a.center toView:rootView].y - [b.superview convertPoint:b.center toView:rootView].y;
    return distanceY;
}

+ (UIWindow *)topMostWindow {
    return [[UIApplication sharedApplication].windows lastObject];
}

+ (BOOL)isPresentedViewController:(UIViewController *)viewController {
    BOOL isPresented = ((viewController.parentViewController && viewController.parentViewController.modalViewController == viewController) ||
                    //or if I have a navigation controller, check if its parent modal view controller is self navigation controller
                    ( viewController.navigationController && viewController.navigationController.parentViewController && viewController.navigationController.parentViewController.modalViewController == viewController.navigationController) ||
                    //or if the parent of my UITabBarController is also a UITabBarController class, then there is no way to do that, except by using a modal presentation
                    [[[viewController tabBarController] parentViewController] isKindOfClass:[UITabBarController class]]);
    
    //iOS 5+
    if (!isPresented && [viewController respondsToSelector:@selector(presentingViewController)]) {
        
        isPresented = ((viewController.presentingViewController && viewController.presentingViewController.modalViewController == viewController) ||
                   //or if I have a navigation controller, check if its parent modal view controller is self navigation controller
                   (viewController.navigationController && viewController.navigationController.presentingViewController && viewController.navigationController.presentingViewController.modalViewController == viewController.navigationController) ||
                   //or if the parent of my UITabBarController is also a UITabBarController class, then there is no way to do that, except by using a modal presentation
                   [[[viewController tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]);
        
    }
    
    return isPresented;
}

+ (void)correctOrientation:(UIViewController *)viewController {
    //以下代码是做屏幕方向校正之用
    UIViewController *tempVC = [[SBBaseViewController alloc]init];
    UIViewController *actionViewController = viewController ? viewController : [ViewUtil rootViewController];
    [actionViewController presentViewController:tempVC animated:NO completion:nil];
    [tempVC dismissViewControllerAnimated:NO completion:nil];
}

+ (NSMutableArray *)getGestureRecognizers:(UIView *)view {
	NSMutableArray *grs = [NSMutableArray arrayWithCapacity:10];
	if (view.gestureRecognizers) {
		[grs addObjectsFromArray:view.gestureRecognizers];
	}
	
	for (UIView *subView in view.subviews) {
		NSMutableArray *subGrs = [ViewUtil getGestureRecognizers:subView];
		[grs addObjectsFromArray:subGrs];
	}
	
	return grs;
}

+ (UIColor *)colorFromRgbValue:(NSNumber *)rgbNumber {
    long rgbValue = [rgbNumber longValue];
    UIColor *color = [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0];
    return color;
}

#pragma mark - iPad Specific Methods

+ (void)splitViewController:(UISplitViewController *)splitViewController hideMasterView:(BOOL)hide {
    //    [splitViewController setHidesMasterViewInPortrait:NO];
    SEL selector = [ViewUtil generate:[NSArray arrayWithObjects:@"setHides",@"temp",@"MasterView",@"temp", @"InPortrait:",@"temp",nil]];
    [LangUtil target:splitViewController performSelector:selector withObjects:[NSArray arrayWithObject:[NSNumber numberWithBool:hide]] hasReturnValue:NO];
}

+ (void)showRemindText:(NSString *)text disappearAfterDelay:(float)delay {
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[ViewUtil topMostWindow] animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[ViewUtil rootView] animated:YES];
	hud.mode = MBProgressHUDModeText;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        hud.detailsLabelFont = [UIFont boldSystemFontOfSize:17];
        //        hud.labelFont = [UIFont boldSystemFontOfSize:17];
    }
	hud.detailsLabelText = text;
    //	hud.margin = 6.f;
    //	hud.yOffset = 60.f;
	hud.removeFromSuperViewOnHide = YES;
	[hud hide:YES afterDelay:delay];
}
@end
