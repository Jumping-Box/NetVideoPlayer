//
//  SBMediaPlayerItem.m
//  Player
//
//  Created by 張宗飛 on 12-11-22.
//  Copyright (c) 2012年 zzf. All rights reserved.
//

#import "SBMediaItem.h"
//#import <Common/Common.h>
//#import "FileManager.h"

@implementation SBMediaItem

@synthesize url = _url;
@synthesize title = _title;
@synthesize thumbnailUrl = _thumbnailUrl;
@synthesize userInfo = _userInfo;
@synthesize identifier;
@synthesize objectid;
@synthesize starttime;
#pragma mark - Constructors

+ (id)itemWithURL:(NSURL *)url {
    __autoreleasing id item = [[SBMediaItem alloc] initWithURL:url];
    return item;
}

+ (id)itemWithSystemFilePath:(NSString *)filePath {
    __autoreleasing id item = [[SBMediaItem alloc] initWithSystemFilePath:filePath];
    return item;
}

+ (id)itemWithLocalFilePath:(NSString *)filePath {
    __autoreleasing id item = [[SBMediaItem alloc] initWithLocalFilePath:filePath];
    return item;
}

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        _title = [[url path] lastPathComponent];
        self.identifier = nil;
        self.objectid = nil;
        self.starttime = -1.0;
        //_thumbnailUrl = url;
    }
    return self;
}

- (id)initWithSystemFilePath:(NSString *)filePath {
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    return [self initWithURL:fileUrl];

}

- (id)initWithLocalFilePath:(NSString *)filePath {
    NSString *systemFilePath = filePath;//[FileManager convertToSystemPath:filePath];
    return [self initWithSystemFilePath:systemFilePath];
}

-(MEDIA_TYPE)getType
{
    if(self.url != nil)
    {
        if([self.url isFileURL])
            return _OTHER_LOCAL_FILE;
        else
        {
            NSString *scheme = [[self.url scheme] lowercaseString];
            NSString *host = [self.url host];
            if (host != nil)
            {
                if([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
                {
                    if(self.userInfo == nil)
                        return _OTHER_LOCAL_FILE;
                    else
                        return _MT_ONLINE_VIDEO;
                }
            }
            else
            {
                NSString *strExt = [[self.url pathExtension] lowercaseString];
                if([strExt isEqualToString:@"m3u8"])
                    return _M3U8_LOCAL_FILE;
            }
        }
    }
    else
    {
        if(self.userInfo != nil)
            return _MT_ONLINE_VIDEO;
    }
    return _UNKNOWN_MEDIA;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"[%@]", [self.class description]];
    [description appendFormat:@"Title = %@, ", self.title];
    [description appendFormat:@"URL = %@", self.url];
    return description;
}

@end
