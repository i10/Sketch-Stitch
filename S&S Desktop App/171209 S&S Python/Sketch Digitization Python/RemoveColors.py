import numpy as np
import cv2

#Load the image
imgpath = r'C:/Users/kirill/Google Drive/S&S Implementation/output_img.JPG'

# load the image
image = cv2.imread(imgpath)

hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

lower = np.array([130,20,50])
upper = np.array([179,255,255])

# Threshold the HSV image
mask = cv2.inRange(hsv, lower, upper)


# Bitwise-AND mask and original image
res = cv2.bitwise_and(image,image, mask= mask)
res = cv2.blur(res,(5,5))

imgDISP1 = cv2.resize(image,(0, 0), fx=0.2, fy=0.2)
cv2.imshow('frame',imgDISP1)
imgDISP2 = cv2.resize(mask,(0, 0), fx=0.2, fy=0.2)
cv2.imshow('mask',imgDISP2)
imgDISP3 = cv2.resize(res,(0, 0), fx=0.2, fy=0.2)
cv2.imshow('res',imgDISP3)
cv2.waitKey(0)
cv2.destroyAllWindows()