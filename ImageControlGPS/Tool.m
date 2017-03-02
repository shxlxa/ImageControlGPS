//
//  Tool.m
//  ImageControlGPS
//
//  Created by aoni on 17/2/23.
//  Copyright © 2017年 aoni. All rights reserved.
//

#import "Tool.h"
#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>
#define kCustomPhotosAlbumDirectory @"image"



@implementation Tool

/* 设置图片的gps信息
 * lat、longi：经纬度  经度113.921050  纬度22.579225
 * data：     图片数据
 * imgFilepath:信息写进图片，将图片保存到的路径(imageName)
 */
+(BOOL)setGPSToImageByLat:(double)lat lon:(double)longi imgData:(NSData *)data newImgFilePath:(NSString*)imgFilepath
{
    if(!data || [data length] == 0 ||!imgFilepath || [imgFilepath length] <= 0)
    {
        return NO;
    }
    CGImageSourceRef source =CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    NSDictionary *dict = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSMutableDictionary *metaDataDic = [dict mutableCopy];
    //GPS
    NSMutableDictionary *gpsDic =[NSMutableDictionary dictionary];
    //[gpsDic setObject:@"N"forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
    [gpsDic setObject:[NSNumber numberWithDouble:lat] forKey:(NSString*)kCGImagePropertyGPSLatitude];
    //[gpsDic setObject:@"E"forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
    [gpsDic setObject:[NSNumber numberWithDouble:longi] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    [metaDataDic setObject:gpsDic forKey:(NSString*)kCGImagePropertyGPSDictionary];
    //其他exif信息
    NSMutableDictionary *exifDic =[[metaDataDic objectForKey:(NSString*)kCGImagePropertyExifDictionary]mutableCopy];
    if(!exifDic)
    {
        exifDic = [NSMutableDictionary dictionary];
    }
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc]init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *EXIFFormattedCreatedDate =[dateFormatter stringFromDate:[NSDate date]];
    [exifDic setObject:EXIFFormattedCreatedDate forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
    
    [metaDataDic setObject:exifDic forKey:(NSString*)kCGImagePropertyExifDictionary];
    
    //写进图片
    CFStringRef UTI = CGImageSourceGetType(source);
    NSMutableData *data1 = [NSMutableData data];
    CGImageDestinationRef destination =CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data1, UTI, 1,NULL);
    if(!destination)
    {
        return NO;
    }
    
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metaDataDic);
    if(!CGImageDestinationFinalize(destination))
    {
        return NO;
    }
    
    //获取documents目录
    NSString *directoryDocuments = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //文件的目标路径
    NSString *destDirect = [directoryDocuments stringByAppendingFormat:@"/%@",kCustomPhotosAlbumDirectory];
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL isDir = YES;
    if(![mgr fileExistsAtPath:destDirect isDirectory:&isDir])
    {
        //原图路径不存在，创建该路径
        if(![mgr createDirectoryAtPath:destDirect withIntermediateDirectories:YES attributes:nil error:nil])
        {
            return NO;
        }
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",destDirect,imgFilepath];
    [data1 writeToFile:path atomically:YES];
    NSLog(@"保存成功！path = %@ end",path);
    
    CFRelease(destination);
    CFRelease(source);
    
    return YES;
}


//获取图片的exif、gps等信息(path：图片路径)
//获取不到exif信息？？？
+(CLLocationCoordinate2D )getGPSByImageFilePath:(NSString*)path
{
    CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(0, 0);
    if(!path || [path length] == 0){
        return coor;
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if(!source){
        return coor;
    }
    
    NSDictionary *dd = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(NSString*)kCGImageSourceShouldCache, nil];
    CFDictionaryRef dict =CGImageSourceCopyPropertiesAtIndex(source, 0, (__bridge CFDictionaryRef)dd);
    if(!dict){
        return coor;
    }
    
//    CFDictionaryRef exif =CFDictionaryGetValue(dict, kCGImagePropertyExifDictionary);
//    if(!exif){
//        return coor;
//    } else {
//        //日期
//        NSString *date = (__bridge NSString*)(CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeDigitized));
//        NSLog(@"%@",date);
//    }

    //获得GPS 的 dictionary
    CFDictionaryRef gps =CFDictionaryGetValue(dict, kCGImagePropertyGPSDictionary);
    if(!gps){
        NSLog(@"该图片没有gps信息");
        return coor;
    }
    //获取经纬度
    NSString *lat = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
    NSString *lon = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
    
    
    CFRelease(dict);
//    CFRelease(exif);
    CFRelease(gps);
    NSLog(@"%@ %@",lat,lon);
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([lat doubleValue],[lon doubleValue]);
    
    return coordinate;
}

+ (NSArray *)getBundleImageNum{
    NSMutableArray *nums = [NSMutableArray array];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSString *directoryDocuments = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *destDirect = [directoryDocuments stringByAppendingFormat:@"/%@",kCustomPhotosAlbumDirectory];
    NSArray *files = [fileManage subpathsAtPath:destDirect];
    for (NSString *fileName in files) {
        if ([fileName.lowercaseString hasSuffix:@"png"]) {
            [nums addObject:fileName];
        }
    }
    return nums;
}



@end
