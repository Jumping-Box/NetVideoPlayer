//
//  SBMediaPlayerItem.h
//  Player
//
//  Created by 張宗飛 on 12-11-22.
//  Copyright (c) 2012年 zzf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _MEDIA_TYPE{
   _UNKNOWN_MEDIA,
   _M3U8_LOCAL_FILE,
   _OTHER_LOCAL_FILE,
   _MT_ONLINE_VIDEO,
   _OTHER_ONLINE_VIDEO,
}MEDIA_TYPE;

@interface SBMediaItem : NSObject

@property(nonatomic,strong) NSURL *url;
@property(nonatomic,strong) NSString *title;
@property(nonatomic,strong) NSURL *thumbnailUrl;
@property(nonatomic,strong) id userInfo;
@property(nonatomic,strong) NSString * identifier;
@property(nonatomic,strong) NSURL * objectid;
@property(nonatomic) float starttime;

+ (id)itemWithURL:(NSURL *)url;
+ (id)itemWithSystemFilePath:(NSString *)filePath;
+ (id)itemWithLocalFilePath:(NSString *)filePath;
- (id)initWithURL:(NSURL *)url;
- (id)initWithSystemFilePath:(NSString *)filePath;
- (id)initWithLocalFilePath:(NSString *)filePath;

-(MEDIA_TYPE)getType;

@end
