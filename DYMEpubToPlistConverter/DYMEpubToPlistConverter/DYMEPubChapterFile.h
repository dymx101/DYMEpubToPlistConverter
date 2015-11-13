//
//  DYMEPubChapterFile.h
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/13.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYMEPubChapterFile : NSObject
@property (nonatomic, copy) NSString *chapterID;
@property (nonatomic, copy) NSString *href;
@property (nonatomic, copy) NSString *mediaType;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@end
