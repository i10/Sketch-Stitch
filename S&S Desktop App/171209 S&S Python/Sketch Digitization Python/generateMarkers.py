import ar_markers
import cv2

from ar_markers.marker import HammingMarker

img = HammingMarker.generate()
img = img.generate_image()

i = 1

while i <= 10:
    img = HammingMarker.generate()
    markerid=img.id
    img = img.generate_image()
    cv2.imwrite(r'C:\Users\kirill\Desktop\markers\marker'+str(markerid)+'.JPG', img)
    i=i+1
