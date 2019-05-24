import cv2
import numpy as np
import ar_markers

import ar_markers.detect as arm

#Load the image
imgpath = r'C:\Users\Kirill Timchenko\Desktop\input_img.jpg'
img = cv2.imread(imgpath,cv2.IMREAD_COLOR)
print("Image loaded successfully.")

#Rotate the image

markersinit = arm.detect_markers(img)
print("Markers found!")
print(markersinit)