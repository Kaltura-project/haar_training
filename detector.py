#!/usr/bin/env python3

import sys
from queue import PriorityQueue
import cv2
import numpy as np

sign_cascade = cv2.CascadeClassifier("classifier3/cascade.xml")

img = cv2.imread(sys.argv[1])
numrec = int(sys.argv[2])
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

signs = sign_cascade.detectMultiScale(gray, 1.1, 5)
print(len(signs), "signs detected.")

q = PriorityQueue()

for sign in signs:
    x_pos, y_pos, width, height = sign
    area = width * height
    # q.put((-area, (x_pos, y_pos), (x_pos + width, y_pos + height)))
    q.put((-area, (int(x_pos + ((width - height) / 2)), y_pos),
           (int(x_pos + ((width - height) / 2) + height), y_pos + height)))

if(len(signs) < numrec):
    numrec = len(signs)

for x in range(numrec):
    rec = q.get()
    cv2.rectangle(img, rec[1], rec[2], (255, 0, 0), 8)

cv2.imwrite("testrec.png", img)


cv2.destroyAllWindows()
