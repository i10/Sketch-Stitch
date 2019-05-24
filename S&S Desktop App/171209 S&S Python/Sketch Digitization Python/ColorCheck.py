import cv2
import numpy as np
import matplotlib.image as mat
import matplotlib.pyplot as plt
import matplotlib.colors as col

imgpath = r'C:\Users\Kirill Timchenko\Desktop\input_img.JPG'


image = cv2.resize(cv2.imread(imgpath, cv2.IMREAD_COLOR),(0, 0), fx=0.2, fy=0.2)
res = cv2.cvtColor(image,cv2.COLOR_BGR2RGB)

x = res[2]
print(x[0])
cv2.imshow('RangeFinder',image)
cv2.waitKey(0)
cv2.destroyAllWindows()