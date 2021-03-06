/*****************************************************************************
 * VLCConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define kVLCVersionCodename @"The Great Shark Hunt"

#define kVLCSettingPasscodeKey @"Passcode"
#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingStretchAudioOnValue @"1"
#define kVLCSettingStretchAudioOffValue @"0"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @(0)
#define kVLCSettingSkipLoopFilterNonRef @(1)
#define kVLCSettingSkipLoopFilterNonKey @(3)
#define kVLCSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define kVLCSettingSubtitlesFont @"quartztext-font"
#define kVLCSettingSubtitlesFontDefaultValue @"HelveticaNeue"
#define kVLCSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define kVLCSettingSubtitlesFontSizeDefaultValue @"16"
#define kVLCSettingSubtitlesFontColor @"quartztext-color"
#define kVLCSettingSubtitlesFontColorDefaultValue @"16777215"
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @(0)
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(9999)
#define kVLCSettingsDecrapifyTitles = @"MLDecrapifyTitles";

#define kVLCRecentURLs @"recent-urls"
#define kVLCPrivateWebStreaming @"private-streaming"

#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"

#define kVLCLastFTPServer @"last-ftp-server"
#define kVLCLastFTPLogin @"last-ftp-login"
#define kVLCLastFTPPassword @"last-ftp-pass"

#define kSupportedFileExtensions @"\\.(3gp|3gp|3gp2|3gpp|amv|asf|avi|axv|divx|dv|flv|f4v|gvi|gxf|m1v|m2p|m2t|m2ts|m2v|m4v|mks|mkv|moov|mov|mp2v|mp4|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv|mt2s|mts|mxf|nsv|nuv|oga|ogg|ogm|ogv|ogx|spx|ps|qt|rec|rm|rmvb|tod|ts|tts|vob|vro|webm|wm|wmv|wtv|xesc|m3u8)$"
//#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil)$"

/* 由于部分字幕格式目前不能支持，在这里去掉 */
/* 经过测试，cdg，aqt，jss，psb，rt，smil未找到测试文件，srt能完美支持字幕相关设置，其他格式能打开显示，但设置无效。另几种目前解析会崩溃，已去掉 */
#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|aqt|jss|psb|rt|smi|txt|smil)$"
#define kSupportedAudioFileExtensions @"\\.(aac|aiff|aif|amr|aob|ape|axa|flac|it|m2a|m4a|mka|mlp|mod|mp1|mp2|mp3|mpa|mpc|oga|oma|opus|rmi|s3m|spx|tta|voc|vqf|wav|wma|wv|xa|xm)$"

#define kBlobHash @"521923d214b9ae628da7987cf621e94c4afdd726"

#if TARGET_IPHONE_SIMULATOR
#define WifiInterfaceName @"en1"
#else
#define WifiInterfaceName @"en0"
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define SYSTEM_RUNS_IOS7_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")

#ifdef DEBUG
#define APLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define APLog(format, ...)
#endif
