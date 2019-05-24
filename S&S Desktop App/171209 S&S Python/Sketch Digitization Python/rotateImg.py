import cv2
import numpy as np
import ar_markers

import ar_markers.detect as arm


#Load the image
imgpath = r'C:\Users\Kirill Timchenko\Desktop\input_img_marked.JPG'
img = cv2.imread(imgpath,cv2.IMREAD_COLOR)


#Rotate the image

markersinit = arm.detect_markers(img)
centerbot = markersinit[0].center
centertop = markersinit[1].center
print(markersinit)

dst = img
rows,cols,x = dst.shape
M = cv2.getRotationMatrix2D((cols/2,rows/2),1,1)

while not centertop[0]-10 < centerbot[0] < centertop[0]+10:
    
    dst = cv2.warpAffine(dst,M,(cols,rows))
    markers = arm.detect_markers(dst)
    centerbot = markers[0].center
    centertop = markers[2].center
    print(markers)

imgDISP = cv2.resize(dst,(0, 0), fx=0.2, fy=0.2)
cv2.imshow('Preview of processed image. Press any key to confirm and save.',imgDISP)
cv2.waitKey(0)
cv2.destroyAllWindows()