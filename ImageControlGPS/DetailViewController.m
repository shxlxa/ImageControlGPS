//
//  DetailViewController.m
//  ImageControlGPS
//
//  Created by aoni on 17/2/24.
//  Copyright © 2017年 aoni. All rights reserved.
//

#import "DetailViewController.h"
#import "Tool.h"
#import <MapKit/MapKit.h>

@interface DetailViewController ()<UIScrollViewDelegate,UIGestureRecognizerDelegate,MKMapViewDelegate>

@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) NSMutableArray *imageList;
// 显示地图的类
@property (nonatomic, strong) MKMapView  *mapView;
@property (nonatomic, strong) MKPointAnnotation *currentAnnotation;


@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    [self addScrollView];
    [self.view addSubview:self.mapView];
    [self setAnnotationWithLatutude:22.5794466 longitude:113.92112];
}
//创建地图
- (void)setAnnotationWithLatutude:(CGFloat )latitude longitude:(CGFloat )longitude{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MKCoordinateSpan span = MKCoordinateSpanMake(0.03, 0.03);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView removeAnnotation:self.currentAnnotation];
    MKPointAnnotation *ann=[[MKPointAnnotation alloc] init];
    ann.coordinate=coordinate;
    ann.title=@"你好";
    ann.subtitle=@"我是大头针，我的头很大";
    self.currentAnnotation = ann;
    [self.mapView addAnnotation:self.currentAnnotation];

    [self.mapView setRegion:region animated:YES];
}

- (MKMapView *)mapView{
    if (!_mapView) {
        CGRect rect = CGRectMake(0, 260, kScreenWidth, kScreenHeight-260);
        _mapView = [[MKMapView alloc] initWithFrame:rect];
        _mapView.delegate = self;
        _mapView.mapType = MKMapTypeStandard;
    }
    return _mapView;
}

- (void)addScrollView{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 250)];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    // 设置scrollView的contentSize为n张图片的总宽度
    _scrollView.contentSize = CGSizeMake(kScreenWidth*(self.imageList.count), 0);
    // 按页滚动，滚动的大小，是以 scrollView.bounds.size.width 基础去滚动
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.tag = 101;
    [_scrollView setContentOffset:CGPointMake(kScreenWidth*_selectIndex, 0) animated:NO];
    [self.view addSubview:_scrollView];
    
    for (int i=0; i<self.imageList.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*kScreenWidth, 0, kScreenWidth, 250)];
        NSString *destDirect = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/image"];
        NSString *imagePath = [destDirect stringByAppendingPathComponent:self.imageList[i]];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_scrollView addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureHandle:)];
        pinchGesture.delegate = self;
        [imageView addGestureRecognizer:pinchGesture];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    NSInteger index = scrollView.contentOffset.x / kScreenWidth;
    NSString *directoryDocuments = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/image"];
    NSString *imagePath = [directoryDocuments stringByAppendingPathComponent:self.imageList[index]];
    CLLocationCoordinate2D coordinate = [Tool getGPSByImageFilePath:imagePath];
    [self setAnnotationWithLatutude:coordinate.latitude longitude:coordinate.longitude];
}

// 捏合手势处理函数
- (void)pinchGestureHandle:(UIPinchGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        //捏合手势中scale属性记录的缩放比例
        if (gesture.scale < 2) {
            gesture.view.transform = CGAffineTransformMakeScale(gesture.scale, gesture.scale);
        }
    }
    if(gesture.state==UIGestureRecognizerStateEnded && gesture.scale < 1.0) {
        [UIView animateWithDuration:0.5 animations:^{
            gesture.view.transform = CGAffineTransformIdentity;//取消一切形变
        }];
    }
}

- (NSMutableArray *)imageList{
    if (!_imageList) {
        _imageList = [NSMutableArray arrayWithArray:[Tool getBundleImageNum]];
    }
    return _imageList;
}




@end
