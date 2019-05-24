import numpy as np
import cv2


purplelow = np.uint8([[[63,28,110 ]]])
hsv_purplelow = cv2.cvtColor(purplelow,cv2.COLOR_BGR2HSV)
print(hsv_purplelow)