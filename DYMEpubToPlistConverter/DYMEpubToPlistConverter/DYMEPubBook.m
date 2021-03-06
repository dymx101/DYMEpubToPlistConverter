//
//  DYMEPubBook.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/13.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEPubBook.h"
#import <ZipArchive/ZipArchive.h>
#import <TBXML/TBXML.h>
#import "DYMEPubChapterFile.h"

@interface DYMEPubBook ()

@property (nonatomic, strong) NSDictionary  *chapterFileDic;

@property (nonatomic, strong) NSDictionary  *chapterFileDicByHref;

@property (nonatomic, strong) NSArray       *spines;

/// opf文件路径
@property (nonatomic, strong) NSString *opfFilePath;
/// 内容目录路径
@property (nonatomic, strong) NSString *contentPath;
/// TOC路径
@property (nonatomic, strong) NSString *tocPath;

@end

@implementation DYMEPubBook

-(instancetype)initWithEPubPath:(NSString *)epubPath
{
    self = [super init];
    if (self) {
        _epubPath = epubPath;
    }
    return self;
}

-(NSString *)bookName {
    NSString *lastComponent = [_epubPath lastPathComponent];
    return [lastComponent componentsSeparatedByString:@"."].firstObject;
}

-(NSString *)unzipPath {
    NSString *bookName = self.bookName;
    if (bookName) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        return [documentPath stringByAppendingPathComponent:bookName];
    }
    
    return nil;
}

-(NSString *)plistPath {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentPath stringByAppendingPathComponent:@"_Converted"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:plistPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return plistPath;
}

-(void)unzip {
    ZipArchive *za = [[ZipArchive alloc] init];
    NSString *unzipPath = self.unzipPath;
    
    if (unzipPath && [za UnzipOpenFile:_epubPath]) {
        
        BOOL ret = [za UnzipFileTo:unzipPath overWrite:YES];
        if (ret) {
//            NSLog(@"Unzip OK!\nfrom: %@\nto: %@ ", _epubPath, unzipPath);
        } else {
//            NSLog(@"Unzip failed!\nfrom: %@\nto: %@ ", _epubPath, unzipPath);
        }
        
        [za UnzipCloseFile];
    }
}

-(void)parse {
    
    [self unzip];
    
    NSString *opfPath = [self opfPathFromMetaContainer];
    self.opfFilePath = opfPath;
    self.contentPath = [opfPath stringByDeletingLastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:opfPath]) {
        NSLog(@"content opf file:%@ 不存在啊", opfPath);
        return;
    }
    
    self.tocPath = [self parseOpfContents];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.tocPath]) {
        NSLog(@"toc file:%@ 不存在啊", self.tocPath);
    }
    
    [self parseTocNcx];
    
    [self loadContents];
    
    [self convertToPlist];
}

#pragma mark - xml parse
- (NSString *) opfPathFromMetaContainer {
    
    NSString *unzipPath = self.unzipPath;
    NSString *metaPath = [unzipPath stringByAppendingPathComponent:@"META-INF/container.xml"];
    
    NSString *metaString = [NSString stringWithContentsOfFile:metaPath encoding:NSUTF8StringEncoding error:nil];
//    NSLog(@"meta container:%@", metaString);
    TBXML *metaxml = [TBXML tbxmlWithXMLString:metaString error:nil];
    TBXMLElement *root = metaxml.rootXMLElement;
    TBXMLElement *rootfiles = root->currentChild;
    
    if (rootfiles) {
        TBXMLElement *rootfile = rootfiles->firstChild;
        
        while (rootfile) {
            if ([[TBXML valueOfAttributeNamed:@"media-type" forElement:rootfile] isEqualToString:@"application/oebps-package+xml"]) {
                
                NSString *fullPath = [TBXML valueOfAttributeNamed:@"full-path" forElement:rootfile];
                NSString *fullBookPath = [unzipPath stringByAppendingPathComponent:fullPath];
                return fullBookPath;
                
            } else {
                rootfile = rootfile->nextSibling;
            }
        }
    }
    
    return nil;
}

- (NSString *)parseOpfContents {
    
    NSString *opfPath = self.opfFilePath;
    NSString *content = [NSString stringWithContentsOfFile:opfPath encoding:NSUTF8StringEncoding error:nil];
    
//    NSLog(@"content opf:%@", content);
    TBXML *contentxml = [TBXML tbxmlWithXMLString:content error:nil];
    
    // Creator
    TBXMLElement *metaData = [TBXML childElementNamed:@"metadata" parentElement:contentxml.rootXMLElement];
    if (metaData != nil) {
        TBXMLElement *creator = [TBXML childElementNamed:@"dc:creator" parentElement:metaData];
        if (creator != nil) {
            _creator = [TBXML textForElement:creator];
        }
        
        TBXMLElement *identifier = [TBXML childElementNamed:@"dc:identifier" parentElement:metaData];
        if (identifier != nil) {
            _identifier = [TBXML textForElement:identifier];
        }
        
        TBXMLElement *desc = [TBXML childElementNamed:@"dc:description" parentElement:metaData];
        if (desc != nil) {
            _desc = [TBXML textForElement:desc];
        }
        
        TBXMLElement *title = [TBXML childElementNamed:@"dc:title" parentElement:metaData];
        if (title != nil) {
            _title = [TBXML textForElement:title];
        }
    }
    
    // Manifest
    TBXMLElement *manifest = [TBXML childElementNamed:@"manifest" parentElement:contentxml.rootXMLElement];
    TBXMLElement *item = manifest->firstChild;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dictByHref = [[NSMutableDictionary alloc] init];
    while (item) {
        DYMEPubChapterFile *file = [DYMEPubChapterFile new];
        file.chapterID = [TBXML valueOfAttributeNamed:@"id" forElement:item];
        file.href = [TBXML valueOfAttributeNamed:@"href" forElement:item];
        file.mediaType = [TBXML valueOfAttributeNamed:@"media-type" forElement:item];
        
        [dict setObject:file forKey:file.chapterID];
        [dictByHref setObject:file forKey:file.href];
        
        item = item->nextSibling;
    }
    self.chapterFileDic = [NSDictionary dictionaryWithDictionary:dict];
    self.chapterFileDicByHref = [NSDictionary dictionaryWithDictionary:dictByHref];
    
    // Spine
    TBXMLElement *spine = [TBXML childElementNamed:@"spine" parentElement:contentxml.rootXMLElement];
    
    TBXMLElement *itemref = spine->firstChild;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    while (itemref) {
        NSString *idref = [TBXML valueOfAttributeNamed:@"idref" forElement:itemref];
        [array addObject:idref];
        
        itemref = itemref->nextSibling;
    }
    self.spines = [NSArray arrayWithArray:array];
    
    // TOC
    NSString *tocid = [TBXML valueOfAttributeNamed:@"toc" forElement:spine];
    
    DYMEPubChapterFile *file = self.chapterFileDic[tocid];
    return [_contentPath stringByAppendingPathComponent:file.href];
}

- (void) parseTocNcx {
    NSString *tocpath = self.tocPath;
    NSString *tocString = [NSString stringWithContentsOfFile:tocpath encoding:NSUTF8StringEncoding error:nil];

    NSString *navMapKey = nil, *navPointKey = nil;
    if ([tocString rangeOfString:@"ncx:ncx"].location != NSNotFound) {
        navMapKey = @"ncx:navMap";
        navPointKey = @"ncx:navPoint";
    } else {
        navMapKey = @"navMap";
        navPointKey = @"navPoint";
    }
    
    TBXML *tocxml = [TBXML tbxmlWithXMLString:tocString error:nil];
//    NSLog(@"toc ncx content:%@", tocString);
    
    // NAV Map
    TBXMLElement *navmap = [TBXML childElementNamed:navMapKey parentElement:tocxml.rootXMLElement];
    TBXMLElement *navpoint = NULL;
    if (navmap != NULL) {
        navpoint = [TBXML childElementNamed:navPointKey parentElement:navmap];
    }
    
    // chapter标题
    while (navpoint) {
        
        [self goThroughNavPoint:navpoint naviPointKey:navPointKey];
        
        navpoint = navpoint->nextSibling;
    }
}

-(void)goThroughNavPoint:(TBXMLElement *)navPoint naviPointKey:(NSString *)navPointKey {
    
    if (navPoint) {
        
        TBXMLElement *navLabel = [self extractNavPoint:navPoint];
        
        TBXMLElement *nextSibling = navLabel->nextSibling;
        while (nextSibling) {
            
            NSString *siblingName = [NSString stringWithUTF8String:nextSibling->name];
            if ([siblingName isEqualToString:navPointKey]) {
                [self goThroughNavPoint:nextSibling naviPointKey:navPointKey];
            }
            
            nextSibling = nextSibling->nextSibling;
        }
    }
}

-(TBXMLElement *)extractNavPoint:(TBXMLElement *)navPoint {
    if (navPoint) {
        NSString *tocid = [TBXML valueOfAttributeNamed:@"id" forElement:navPoint];
        TBXMLElement *navLabel = navPoint->firstChild;
        TBXMLElement *text = navLabel->firstChild;
        NSString *title = [TBXML textForElement:text];
        
        DYMEPubChapterFile *file = self.chapterFileDic[tocid];
        if (file == nil) {
            TBXMLElement *content = navLabel->nextSibling;
            NSString *src = [TBXML valueOfAttributeNamed:@"src" forElement:content];
            file = self.chapterFileDicByHref[src];
        }
        file.title = title;
        
        return navLabel;
    }
    
    return nil;
}


-(void)loadContents {
    NSArray *allChapters = [self.chapterFileDic allValues];
    [allChapters enumerateObjectsUsingBlock:^(DYMEPubChapterFile *  _Nonnull chapterFile, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSLog(@"%@", chapterFile);
        if (chapterFile.href && [chapterFile.mediaType isEqualToString:@"application/xhtml+xml"]) {
            NSString *chapterPath = [_contentPath stringByAppendingPathComponent:chapterFile.href];
            NSString *content = [NSString stringWithContentsOfFile:chapterPath encoding:NSUTF8StringEncoding error:nil];
            if (content) {
                // 消除回车换行
                content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                
                // for harry potter!!!
//                content = [content stringByReplacingOccurrencesOfString:@"　　" withString:@""];
//                content = [content stringByReplacingOccurrencesOfString:@"  " withString:@""];
                
                // 转化标签
                content = [content stringByReplacingOccurrencesOfString:@"<h1>" withString:@""];
                content = [content stringByReplacingOccurrencesOfString:@"</h1>" withString:@"\n\n"];
                content = [content stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
                content = [content stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
                content = [content stringByReplacingOccurrencesOfString:@"</p>" withString:@"\n\n"];
                
                // 转化encode字符
                content = [content stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"“"];
                content = [content stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"” "];
                content = [content stringByReplacingOccurrencesOfString:@"&lsquo;" withString:@"‘"];
                content = [content stringByReplacingOccurrencesOfString:@"&rsquo;" withString:@"’ "];
                content = [content stringByReplacingOccurrencesOfString:@"&amp;nbsp;" withString:@" "];
                content = [content stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
                
                content = [self stringByStrippingHTML:content];
                //            NSLog(@"%@", content);
                
                chapterFile.content = content;
            } else {
                NSLog(@"Not a html, mediaType:%@", chapterFile.mediaType);
            }
        }
    }];
}

-(NSString *) stringByStrippingHTML:(NSString *)htmlString {
    NSRange r;
    NSString *s = [htmlString copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

-(NSArray *)sortedChapters {
    NSMutableArray *sortedChapters = [NSMutableArray array];
    [self.spines enumerateObjectsUsingBlock:^(NSString * _Nonnull chapterID, NSUInteger idx, BOOL * _Nonnull stop) {
        DYMEPubChapterFile *chapter = self.chapterFileDic[chapterID];
        if (chapter && [chapter.mediaType isEqualToString:@"application/xhtml+xml"]) {
            [sortedChapters addObject:chapter];
        }
    }];
    
    return sortedChapters;
}

-(void)convertToPlist {
    NSArray *sortedChapter = [self sortedChapters];
    
    NSMutableDictionary *bookDic = [NSMutableDictionary dictionary];
    bookDic[@"status"] = @"已完成";
    bookDic[@"author"] = self.creator;
    bookDic[@"isbn"] = self.identifier; //
    bookDic[@"src"] = @"default.png";
    bookDic[@"title"] = self.title ? : self.bookName;
    bookDic[@"cover"] = @"no_cover.png"; //
    bookDic[@"order"] = @"9999"; //
    
    NSMutableArray *partTitleArr = [NSMutableArray array];
    bookDic[@"partTitleArr"] = partTitleArr;
    [partTitleArr addObject:@"章节列表"];
    
    NSMutableArray *chapterArrArr = [NSMutableArray array];
    bookDic[@"chapterArrArr"] = chapterArrArr;
    
    NSMutableArray *innerChapters = [NSMutableArray array];
    [chapterArrArr addObject:innerChapters];
    
    [sortedChapter enumerateObjectsUsingBlock:^(DYMEPubChapterFile *  _Nonnull chapter, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *chapterDic = [NSMutableDictionary dictionary];
        chapterDic[@"chapterContent"] = chapter.content ? : @"";
        chapterDic[@"chapterTitle"] = chapter.title.length > 0 ? chapter.title : [NSString stringWithFormat:@"第%@章", @(idx + 1)];
        chapterDic[@"chapterSrcs"] = @" ";
        chapterDic[@"href"] = chapter.href;
        
        [innerChapters addObject:chapterDic];
    }];
    
    NSString *plistPath = [[self plistPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", self.bookName]];
    [bookDic writeToFile:plistPath atomically:YES];
    
    NSLog(@"转化完成：\n%@", plistPath);
}

@end
