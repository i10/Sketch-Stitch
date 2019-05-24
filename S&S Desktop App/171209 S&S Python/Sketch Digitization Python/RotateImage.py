import cv2
import numpy as np
import ar_markers.detect as arm

area = 10 #Determines the range of pixels in which both points count as parallel to each other

def rotate(image, idtop, idbot): 
    
    markersinit = arm.detect_markers(image)
    
    for markers in markersinit:
        if markers.id == idbot:
            centerbot=markers.center
        if markers.id == idtop:
            centertop=markers.center
    
    print("Markers found sucessfully!")
    
    dst = image
    rows,cols,x = dst.shape
    M = cv2.getRotationMatrix2D((cols/2,rows/2),1,1)
    
    while not centertop[0]-area < centerbot[0] < centertop[0]+area:
        
        dst = cv2.warpAffine(dst,M,(cols,rows))
        markers = arm.detect_markers(dst)
        for markers in markersinit:
            if markers.id == idbot:
                centerbot=markers.center
            if markers.id == idtop:
                centertop=markers.center
        print(".", end="")
        
    print(".")
    print("Rotation successful.")
    return dst