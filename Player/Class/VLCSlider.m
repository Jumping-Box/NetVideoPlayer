/*****************************************************************************
 * VLCSlider.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSlider.h"
#import "VLCConstants.h"

@implementation VLCOBSlider

- (void)awakeFromNib
{
    [super awakeFromNib];
    UIImage *minTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMinimumTrack.png"];
    UIImage *maxTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMaximumTrack.png"];
    minTrackImage = [minTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, minTrackImage.size.width / 2.0f, 0, minTrackImage.size.width / 2.0f)];
    maxTrackImage = [maxTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, maxTrackImage.size.width / 2.0f, 0, maxTrackImage.size.width / 2.0f)];
    [self setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    [self setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    [self setMinimumTrackImage:minTrackImage forState:UIControlStateHighlighted];
    [self setMaximumTrackImage:maxTrackImage forState:UIControlStateHighlighted];
    
    [self setThumbImage:[UIImage imageNamed:@"PlayerResource.bundle/modernSliderKnob.png"] forState:UIControlStateNormal];
}

//- (void)willMoveToSuperview:(UIView *)newSuperview {
//    [super willMoveToSuperview:newSuperview];
//    [self setThumbImage:[UIImage imageNamed:@"PlayerResource.bundle/modernSliderKnob.png"] forState:UIControlStateNormal];
//    UIImage *minTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMinimumTrack.png"];
//    UIImage *maxTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMaximumTrack.png"];
//    minTrackImage = [minTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, minTrackImage.size.width / 2.0f, 0, minTrackImage.size.width / 2.0f)];
//    maxTrackImage = [maxTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, maxTrackImage.size.width / 2.0f, 0, maxTrackImage.size.width / 2.0f)];
//    [self setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
//    [self setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
//}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        return returnValue;
    } else {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            returnValue.origin.y = 14.;
        } else {
            returnValue.origin.y = 16.;
        }
    }
    return returnValue;
}

@end


@implementation VLCSlider

- (void)awakeFromNib
{
    [super awakeFromNib];
    UIImage *minTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMinimumTrack.png"];
    UIImage *maxTrackImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderMaximumTrack.png"];
    minTrackImage = [minTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, minTrackImage.size.width / 2.0f, 0, minTrackImage.size.width / 2.0f)];
    maxTrackImage = [maxTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, maxTrackImage.size.width / 2.0f, 0, maxTrackImage.size.width / 2.0f)];
    [self setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    [self setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    [self setMinimumTrackImage:minTrackImage forState:UIControlStateHighlighted];
    [self setMaximumTrackImage:maxTrackImage forState:UIControlStateHighlighted];
    
    [self setThumbImage:[UIImage imageNamed:@"PlayerResource.bundle/modernSliderKnob.png"] forState:UIControlStateNormal];
    //    if (SYSTEM_RUNS_IOS7_OR_LATER)
    //        [self setThumbImage:[UIImage imageNamed:@"PlayerResource.bundle/modernSliderKnob.png"] forState:UIControlStateNormal];
    //    else {
    //        self.minimumValueImage = [UIImage imageNamed:@"PlayerResource.bundle/sliderminiValue.png"];
    //        self.maximumValueImage = [UIImage imageNamed:@"PlayerResource.bundle/slidermaxValue.png"];
    //        [self setMinimumTrackImage:[UIImage imageNamed:@"PlayerResource.bundle/sliderminimumTrack.png"] forState:UIControlStateNormal];
    //        [self setMaximumTrackImage:[UIImage imageNamed:@"PlayerResource.bundle/slidermaximumTrack.png"] forState:UIControlStateNormal];
    //        [self setThumbImage:[UIImage imageNamed:@"PlayerResource.bundle/ballSlider.png"] forState:UIControlStateNormal];
    //    }
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        return returnValue;
    } else {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            returnValue.origin.y = 14.;
        } else {
            returnValue.origin.y = 16.;
        }
    }
    return returnValue;
}

@end
