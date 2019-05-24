import cv2
import numpy as np
import ar_markers.detect as arm

#Load the image
imgpath = r'C:\Users\kirill\Google Drive\S&S Implementation\output_img.JPG'
img = cv2.imread(imgpath,cv2.IMREAD_COLOR)
print("Image loaded successfully.")

rows,cols,x = img.shape
uppergrey = 30

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
cv2.imwrite(r'C:\Users\kirill\Google Drive\S&S Implementation\output_img_bgwhite.JPG', img)
print("> Image got saved.")