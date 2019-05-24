#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#include <opencv2/aruco.hpp>

#import <Foundation/Foundation.h>
#import "OpenCV.h"

static void NSImageToMat(NSImage *image, cv::Mat &mat) {
    
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSInteger width = [bitmapImageRep pixelsWide];
    NSInteger height = [bitmapImageRep pixelsHigh];
    CGImageRef imageRef = [bitmapImageRep CGImage];
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
    
    mat = mat8uc3;
}

static NSImage *MatToNSImage(cv::Mat &mat) {
    
    assert(mat.elemSize() == 1 || mat.elemSize() == 3);
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, CV_BGR2RGB);
    }
    
    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [[NSImage alloc]init];
    [image addRepresentation:bitmapImageRep];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

@implementation OpenCV

+ (nonnull NSImage *)resize:(nonnull NSImage *)image :(double) factor {
    double scale = factor;
    cv::Mat input;
    cv::Mat resized;
    NSImageToMat(image, input);
    cv::resize(input, resized, cv::Size(), scale, scale, cv::INTER_LINEAR);
    NSImage *output = MatToNSImage(resized);
    return output;
}

+ (nonnull NSImage *)filterByBounds:(nonnull NSImage *)image :(double) bl :(double) gl :(double) rl :(double) bh :(double) gh :(double) rh :(int) noise :(int) noiseval :(int) coloring :(int) colorSpace :(int) prenoise :(int) prenoiseval{
    
    cv::Mat input;
    cv::Mat inputhsv;
    cv::Mat mask;
    NSImageToMat(image, input);
    input.copyTo(inputhsv);
    cv::Scalar lower = cv::Scalar(bl,gl,rl);
    cv::Scalar upper = cv::Scalar(bh,gh,rh);
    
    if(prenoise == 1){
        cv::fastNlMeansDenoising(input, input, prenoiseval, 7, 21);
    }
    
    if(colorSpace == 1){
        cv::cvtColor(input, inputhsv, CV_BGR2HSV);
    }
    
    cv::inRange(inputhsv, lower, upper, mask);
    cv::cvtColor(mask, mask, CV_GRAY2BGR);
    
    cv::bitwise_and(input, mask, input);
    
    if(noise == 1){
        cv::fastNlMeansDenoising(input, input, noiseval, 7, 21);
    }
    
    NSImage* output = MatToNSImage(input);
    return output;
}

+ (nonnull NSImage *)whiteBackground:(nonnull NSImage *)image{
    
    cv::Mat input;
    NSImageToMat(image, input);
    
    for (int row = 0; row < input.rows; ++row)
    {
        uchar *ptr = input.ptr(row);
        for (int col = 0; col < input.cols; col++)
        {
            uchar * uc_pixel = ptr;
            int a = uc_pixel[0];
            int b = uc_pixel[1];
            int c = uc_pixel[2];
            
            if(a+b+c <= 40){
                uc_pixel[0] = 255;
                uc_pixel[1] = 255;
                uc_pixel[2] = 255;
            }
            
            ptr += 3;
            
        }
    }
    
    NSImage* output = MatToNSImage(input);
    return output;
}

+ (nonnull NSImage *)colorImage:(nonnull NSImage *)image : (int) color : (int) b : (int) g : (int) r{
    
    cv::Mat input;
    cv::Mat mask;
    NSImageToMat(image, input);
    cv::Scalar selected;
    
    if(color > 0){
        selected = cv::Scalar(b,g,r);
    }
    
    for (int row = 0; row < input.rows; ++row)
    {
        uchar *ptr1 = input.ptr(row);
        
        for (int col = 0; col < input.cols; col++)
        {
            uchar * uc_pixel1 = ptr1;
            int b = uc_pixel1[0];
            int g = uc_pixel1[1];
            int r = uc_pixel1[2];
            
            if(b+g+r > 60){
                uc_pixel1[0] = selected[0];
                uc_pixel1[1] = selected[1];
                uc_pixel1[2] = selected[2];
            } else{
                uc_pixel1[0] = 0;
                uc_pixel1[1] = 0;
                uc_pixel1[2] = 0;
            }
            
            ptr1 += 3;
            
        }
        
    }
    
    
    NSImage* output = MatToNSImage(input);
    return output;
    
}

+(NSArray*)getMarkers:(nonnull NSImage*)image{
    cv::Mat input, imageCopy;
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    NSImageToMat(image, input);
    input.copyTo(imageCopy);
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f> > corners;
    cv::aruco::detectMarkers(input, dictionary, corners, ids);
    if(ids.size() == 2){
        int first = ids.at(0);
        int second = ids.at(1);
        NSArray *res = @[@(first),@(second)];
        return res;
    }
    
    NSArray *error = @[@(404)];
    
    return error;
}

+(nonnull NSArray*)getMarkerCenter:(nonnull NSImage*)image :(int)index{
    cv::Mat input;
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    NSImageToMat(image, input);
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f> > corners;
    cv::aruco::detectMarkers(input, dictionary, corners, ids);
    
    if(corners.size() == 2){
        float x1x = corners.at(index).at(0).x;
        float x1y = corners.at(index).at(0).y;
        float x2x = corners.at(index).at(2).x;
        float x2y = corners.at(index).at(2).y;
        
        float resx = round(x1x+0.5*abs(x1x-x2x));
        float resy = round(x1y+0.5*abs(x1y-x2y));
        NSArray *res = @[@(resx),@(resy)];
        
        return res;
    }
    
    NSArray *res = @[@(404)];
    
    return res;
}

+(nonnull NSImage*)cropHoop:(nonnull NSImage*)image :(int)x :(int)y :(int)botx :(int)height :(int)topx :(int) nightmode{
    cv::Mat input;
    NSImageToMat(image, input);
    cv::Mat mask(input.rows, input.cols, CV_8UC3, cv::Scalar(0,0,0));
    cv::Point pt1 = cv::Point(topx, round(y+0.31*height));
    cv::Point pt2 = cv::Point(topx, round(y+0.7*height));
    circle(mask, pt1, 1, cv::Scalar(255, 255, 255), round(height*0.48), 8, 0);
    circle(mask, pt2, 1, cv::Scalar(255, 255, 255), round(height*0.48), 8, 0);
    
    cv::Point rectx = cv::Point(pt1.x-round(height*0.24), pt1.y);
    cv::Rect rect(rectx.x, rectx.y, round(height*0.48), round(0.39*height));
    
    cv::rectangle(mask, rect, cv::Scalar(255, 255, 255), -1);
    cv::bitwise_and(input, mask, input);
    
    cv::Rect myROI(round(topx-0.28*height), y, round(topx+0.28*height), height);
    cv::Mat croppedImage = input(myROI);
    
    int colorbg = 236;
    
    if(nightmode == 1){
        colorbg = 50;
    }
    
    for (int row = 0; row < croppedImage.rows; ++row)
    {
        uchar *ptr = croppedImage.ptr(row);
        for (int col = 0; col < croppedImage.cols; col++)
        {
            uchar * uc_pixel = ptr;
            int a = uc_pixel[0];
            int b = uc_pixel[1];
            int c = uc_pixel[2];
            
            if(a == 0 and b == 0 and c == 0){
                uc_pixel[0] = colorbg;
                uc_pixel[1] = colorbg;
                uc_pixel[2] = colorbg;
            }
            
            ptr += 3;
            
        }
    }
    
    cv::Mat colcut = croppedImage.colRange(0, croppedImage.cols-150);
    
    NSImage* res = MatToNSImage(colcut);
    
    return res;
    
}

+(nonnull NSImage*)getBlackAndWhiteVersion: (nonnull NSImage*)image{
    cv::Mat input;
    NSImageToMat(image,input);
    cv::cvtColor(input, input, CV_BGR2GRAY);
    NSImage* output = MatToNSImage(input);
    return output;
}

+(nonnull NSImage*)deNoise: (nonnull NSImage*)image :(int) value{
    cv::Mat input;
    NSImageToMat(image, input);
    cv::fastNlMeansDenoising(input, input, value, 7, 21);
    NSImage* output = MatToNSImage(input);
    return output;
}
@end



