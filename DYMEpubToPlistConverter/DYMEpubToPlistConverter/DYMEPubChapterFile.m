//
//  DYMEPubChapterFile.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/13.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEPubChapterFile.h"

@implementation DYMEPubChapterFile

-(NSString *)description {
    return [NSString stringWithFormat:@"chapterID:%@, href:%@, mediatype:%@, title:%@", _chapterID, _href, _mediaType, _title];
}

@end
