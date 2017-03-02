//
//  Tool.h
//  ImageControlGPS
//
//  Created by aoni on 17/2/23.
//  Copyright © 2017年 aoni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kScreenHeight  [[UIScreen mainScreen] bounds].size.height
#define kScreenWidth   [[UIScreen mainScreen] bounds].size.width

@interface Tool : NSObject

+(BOOL)setGPSToImageByLat:(double)lat lon:(double)longi imgData:(NSData *)data newImgFilePath:(NSString*)imgFilepath;

+(CLLocationCoordinate2D)getGPSByImageFilePath:(NSString*)path;

+(NSArray *)getBundleImageNum;

@end
