import cv2
import numpy as np

def nothing(x):
    pass

scale = 0.6
imgpath = r'C:\Users\Kirill Timchenko\Desktop\input_img.jpg'

#BlueOnly= 145,0,0 to 197,171,135 in RGB
#RedOnly= 0,0,143 to 131,127,255
#GreenOnly= 0,148,0 to 162,255,145 in RGB


# load the image
image = cv2.resize(cv2.imread(imgpath),(0, 0), fx=scale, fy=scale)
res = cv2.cvtColor(image,cv2.COLOR_BGR2HSV)
cv2.namedWindow('RangeFinder')

# create trackbars for color change
cv2.createTrackbar('LH','RangeFinder',0,255,nothing)
cv2.createTrackbar('LS','RangeFinder',0,255,nothing)
cv2.createTrackbar('LV','RangeFinder',0,255,nothing)

cv2.createTrackbar('UH','RangeFinder',0,255,nothing)
cv2.createTrackbar('US','RangeFinder',0,255,nothing)
cv2.createTrackbar('UV','RangeFinder',0,255,nothing)

while(1): 
    k = cv2.waitKey(1) & 0xFF
    if k == 32:
        break
    
    # get current positions of four trackbars
    lh = cv2.getTrackbarPos('LH','RangeFinder')
    ls = cv2.getTrackbarPos('LS','RangeFinder')
    lv = cv2.getTrackbarPos('LV','RangeFinder')
    
    uh = cv2.getTrackbarPos('UH','RangeFinder')
    us = cv2.getTrackbarPos('US','RangeFinder')
    uv = cv2.getTrackbarPos('UV','RangeFinder')
    
    lower = np.array([lh,ls,lv])
    upper = np.array([uh,us,uv])
    
    img = res

    mask = cv2.inRange(img, lower, upper)
    fin = cv2.bitwise_and(img,img, mask= mask)
    
    vis = np.concatenate((cv2.cvtColor(mask,cv2.COLOR_GRAY2BGR), fin), axis=1)
    vis = cv2.resize(vis,(0, 0), fx=scale, fy=scale)
    cv2.imshow('RangeFinder',vis)

fin = cv2.cvtColor(fin,cv2.COLOR_HSV2BGR)
fin = cv2.fastNlMeansDenoisingColored(fin,None,10,10,7,21)
cv2.imwrite(r'C:\Users\Kirill Timchenko\Desktop\output_filter.JPG', fin)


cv2.destroyAllWindows()