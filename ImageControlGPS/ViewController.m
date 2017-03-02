//
//  ViewController.m
//  ImageControlGPS
//
//  Created by aoni on 17/2/23.
//  Copyright © 2017年 aoni. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <CoreLocation/CoreLocation.h>
#import <ImageIO/ImageIO.h>
#import "Tool.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "DetailViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) float currentLongitude;
@property (nonatomic, assign) float currentLatitude;
@property (nonatomic, strong) UITableView  *tableView;
@property (nonatomic, strong) NSMutableArray *imageList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"拍照" style:UIBarButtonItemStylePlain target:self action:@selector(takePhoto)];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self getLocation];
    [self tableView];
    //获取documents目录
    NSString *directoryDocuments = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //文件的目标路径
    NSString *destDirect = [directoryDocuments stringByAppendingFormat:@"/%@",@"image"];
    
    NSString *imagePath = [destDirect stringByAppendingPathComponent:@"3.png"];
     CLLocationCoordinate2D coor = [Tool getGPSByImageFilePath:imagePath];
    NSLog(@"%f %f",coor.latitude,coor.longitude);
    NSArray *imageArr = [Tool getBundleImageNum];
    if (imageArr.count > 0) {
        for (NSString *imageName in imageArr) {
            NSString *path = [destDirect stringByAppendingPathComponent:imageName];
            CLLocationCoordinate2D coordinate = [Tool getGPSByImageFilePath:path];
            NSLog(@"imageName:%@ 纬度：%f 经度：%f",imageName,coordinate.latitude,coordinate.longitude);
        }
    }
}

- (void)takePhoto{
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerImage.showsCameraControls = YES;
        pickerImage.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:pickerImage.sourceType];
    }
    pickerImage.delegate = self;
    pickerImage.allowsEditing = YES;
    [self presentViewController:pickerImage animated:YES completion:nil];
}

- (void)getLocation{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    //超过10米才重新调用成功回调
    self.locationManager.distanceFilter = 10.0;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
        [self.locationManager requestAlwaysAuthorization]; // 永久授权
        [self.locationManager requestWhenInUseAuthorization]; //使用中授权
    }
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    NSLog(@"经度：%f", newLocation.coordinate.longitude);
//    NSLog(@"纬度：%f", newLocation.coordinate.latitude);
//    NSLog(@"速度：%f 米/秒", newLocation.speed);
    self.currentLongitude = newLocation.coordinate.longitude;
    self.currentLatitude = newLocation.coordinate.latitude;
//    CLGeocoder * geocoder = [[CLGeocoder alloc] init];
//    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
//        
//        NSDictionary *locationInfo = [[NSDictionary alloc]init];
//        for (CLPlacemark * placemark in placemarks) {
//            locationInfo = [placemark addressDictionary];
//        }
//        NSLog(@"city:%@ FormattedAddressLines:%@ Name:%@ State:%@ Street:%@ SubLocality:%@ Thoroughfare:%@",locationInfo[@"City"],locationInfo[@"FormattedAddressLines"],locationInfo[@"Name"],locationInfo[@"State"],locationInfo[@"Street"],locationInfo[@"SubLocality"],locationInfo[@"Thoroughfare"]);
//    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@", error);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
        NSDictionary *dataDict = [info objectForKey:UIImagePickerControllerMediaMetadata];
        NSDictionary *tiffDict = [dataDict objectForKey:@"{TIFF}"];
        NSString *dateTime = tiffDict[@"DateTime"];
        NSData *data = UIImagePNGRepresentation(image);
        [Tool setGPSToImageByLat:self.currentLatitude lon:self.currentLongitude imgData:data newImgFilePath:[NSString stringWithFormat:@"%@.png",dateTime]];
    }
    [self imagePickerControllerDidCancel:picker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self refreshImageList];
    [self.tableView reloadData];
    [self dismissImagePickerController];
}

- (void)dismissImagePickerController {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self.navigationController popToViewController:self animated:YES];
    }
}


- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 60;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.tableFooterView = [[UIView alloc] init];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.imageList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"cell";
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.textLabel.text = self.imageList[indexPath.row];
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DetailViewController *vc = [[DetailViewController alloc] init];
    vc.selectIndex = indexPath.row;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *directoryDocuments = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/image"];
    NSString *imagePath = [directoryDocuments stringByAppendingPathComponent:self.imageList[indexPath.row]];
    NSFileManager *fm = [NSFileManager defaultManager];
    bool isDeleted = [fm removeItemAtPath:imagePath error:nil];
    if (isDeleted) {
        [self refreshImageList];
        //此处不用刷新tableView
    }
    //从列表中删除
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (NSMutableArray *)imageList {
    if (!_imageList) {
        _imageList = [NSMutableArray arrayWithArray:[Tool getBundleImageNum]];
    }
    return _imageList;
}

//refresh ImageList
- (void)refreshImageList{
    [self.imageList removeAllObjects];
    self.imageList = [NSMutableArray arrayWithArray:[Tool getBundleImageNum]];
}


@end
