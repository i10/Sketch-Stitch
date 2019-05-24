import cv2
import numpy as np
import ar_markers

import ar_markers.detect as arm
def adjust_gamma(image, gamma=1.0):

   invGamma = 1.0 / gamma
   table = np.array([((i / 255.0) ** invGamma) * 255
      for i in np.arange(0, 256)]).astype("uint8")

   return cv2.LUT(image, table)

#Define parameters
area = 15
idtop = 597
idbot = 1982

#Load the image
imgpath = r'C:\Users\kirill\Google Drive\S&S Implementation\input_img_marked597x1982.jpg'
img = cv2.imread(imgpath,cv2.IMREAD_COLOR)
print("Image loaded successfully.")

#Rotate the image

markersinit = arm.detect_markers(img)
    
for markers in markersinit:
    if markers.id == idbot:
            centerbot=markers.center
    if markers.id == idtop:
            centertop=markers.center

print(markersinit)   
print("Markers found sucessfully!")
    
dst = img
rows,cols,x = dst.shape
M = cv2.getRotationMatrix2D((cols/2,rows/2),1,1)
    
while not centertop[0]-area < centerbot[0] < centertop[0]+area:
        
    dst = cv2.warpAffine(dst,M,(cols,rows))
    markers = arm.detect_markers(dst)
    #print(markers)
    for marker in markers:
        if marker.id == idbot:
            centerbot=marker.center
        if marker.id == idtop:
            centertop=marker.center
    print(".", end="")
        
print(".")
img = dst
print("Rotation successful.")

#Crop the image
markers = arm.detect_markers(img)

for marker in markers:
    if marker.id == idbot:
        centerbot=marker.center
    if marker.id == idtop:
        centertop=marker.center

difference = int(abs(centertop[1]-centerbot[1])/4)

img = img[centertop[1]+150:centerbot[1]-150, centertop[0]-difference:centertop[0]+difference]

print("Cropping done.")

#Adjust the sharpness
kernel = np.zeros((9,9),np.float32)
kernel[4,4]= 2.0
boxFilter = np.ones((9,9),np.float32)/81.0
kernel = kernel - boxFilter

img = cv2.filter2D(img, -1, kernel)

print("Sharpening done.")

#Adjust the contrast
gamma = 2                                 
adjusted_contrast = adjust_gamma(img, gamma=gamma)
print("Increased contrast.")

#Adjust the exposure
alpha = 1.2
beta = 0
adjusted_exposure = cv2.addWeighted(adjusted_contrast, alpha, np.zeros(img.shape, img.dtype), 0 ,beta)
print("Increased exposure.")

#Remove all the inimportant stuff
hsv = cv2.cvtColor(adjusted_exposure, cv2.COLOR_BGR2HSV)

lower = np.array([130,20,50])
upper = np.array([179,255,255])

# Threshold the HSV image
mask = cv2.inRange(hsv, lower, upper)


# Bitwise-AND mask and original image
res = cv2.bitwise_and(adjusted_exposure,adjusted_exposure, mask= mask)
#adjusted_exposure = cv2.blur(res,(5,5))
img = res

#Replace black background
rows,cols,x = img.shape
uppergrey = 20

print(img.shape)

for i in range(rows):
    for j in range(cols):
        if img[i,j,0] < uppergrey or img[i,j,1] < uppergrey or img[i,j,2] < uppergrey:
            img[i,j,0] = img[i,j,1] = img[i,j,2] = 255

#Display the image
imgDISP = cv2.resize(img,(0, 0), fx=0.2, fy=0.2)
cv2.imshow('Preview of processed image. Press any key to confirm and save.',imgDISP)
cv2.waitKey(0)
cv2.destroyAllWindows()

#Save the image
cv2.imwrite(r'C:\Users\kirill\Google Drive\S&S Implementation\output_img.JPG', img)
print("> Image got saved.")



