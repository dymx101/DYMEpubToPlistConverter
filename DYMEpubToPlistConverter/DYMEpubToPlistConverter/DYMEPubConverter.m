//
//  DYMEPubConverter.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEPubConverter.h"
#import <ZipArchive/ZipArchive.h>
#import <TBXML/TBXML.h>

@interface DYMEPubConverter () {
    
}

@end

@implementation DYMEPubConverter



-(void)loadEpubFiles:(dispatch_block_t)completion {
    
    [DYMEPubConverter doAsync:^{
        
        _epubFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"epub" inDirectory:@"epub"];
        
    } completion:completion];
}

-(NSString *)bookNameAtIndex:(NSUInteger)index {
    if (index < _epubFiles.count) {
        NSString *path = _epubFiles[index];
        NSString *lastComponent = [path lastPathComponent];
        
        return [lastComponent componentsSeparatedByString:@"."].firstObject;
    }
    
    return nil;
}

-(NSString *)bookUnzipPathAtIndex:(NSUInteger)index {
    NSString *bookName = [self bookNameAtIndex:index];
    if (bookName) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        return [documentPath stringByAppendingPathComponent:bookName];
    }
    
    return nil;
}

- (void)unzipBookAtIndex:(NSUInteger)index {
    
    if (index < _epubFiles.count) {
        NSString *path = _epubFiles[index];
        
        ZipArchive *za = [[ZipArchive alloc] init];
        NSString *unzipPath = [self bookUnzipPathAtIndex:index];
        
        if (unzipPath && [za UnzipOpenFile:path]) {
            
            BOOL ret = [za UnzipFileTo:unzipPath overWrite:YES];
            if (ret) {
                NSLog(@"Unzip OK!\nfrom: %@\nto: %@ ", path, unzipPath);
            } else {
                NSLog(@"Unzip failed!\nfrom: %@\nto: %@ ", path, unzipPath);
            }
            
            [za UnzipCloseFile];
        }
    }
}

#pragma mark - parse
-(void)parseAtIndex:(NSUInteger)index {
    NSString *bookUnzipPath = [self bookUnzipPathAtIndex:index];
    NSString *meta = [self parseMetaContainer:bookUnzipPath];
    
}

- (NSString *) parseMetaContainer:(NSString *)bookPath {
    
    NSString *metaPath = [bookPath stringByAppendingPathComponent:@"META-INF/container.xml"];
    
    NSString *metaString = [NSString stringWithContentsOfFile:metaPath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"meta container:%@", metaString);
    TBXML *metaxml = [TBXML tbxmlWithXMLString:metaString error:nil];
    TBXMLElement *root = metaxml.rootXMLElement;
    TBXMLElement *rootfiles = root->currentChild;
    
    if (rootfiles) {
        TBXMLElement *rootfile = rootfiles->firstChild;
        
        while (rootfile) {
            if ([[TBXML valueOfAttributeNamed:@"media-type" forElement:rootfile] isEqualToString:@"application/oebps-package+xml"]) {
                
                NSString *fullPath = [TBXML valueOfAttributeNamed:@"full-path" forElement:rootfile];
                NSString *fullBookPath = [bookPath stringByAppendingPathComponent:fullPath];
                return fullBookPath;
                
            } else {
                rootfile = rootfile->nextSibling;
            }
        }
    }
    
    return nil;
}

#pragma mark - helper
+(void)doAsync:(dispatch_block_t)block completion:(dispatch_block_t)completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (block) {
            block();
        }
        
        dispatch_async(dispatch_get_main_queue(), completionBlock);
    });
}

@end
