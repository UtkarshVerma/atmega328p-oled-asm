#!/bin/env python3

import cv2
import numpy as np
import math

# Display the progress bar
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█', printEnd = "\r"):
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = printEnd)

    if iteration == total:
        print()

# Resize `frame` according to given dimensions and add padding if necessary
def resizeFrame(frame, width, height, inter=cv2.INTER_AREA):
    h, w = frame.shape[:2]
    dimensions = None

    # Top, bottom, left, right borders
    borders = [0, 0, 0, 0]

    # Rescale video in fit-to-height mode
    dimensions = int(np.ceil(w * height / float(h) / 2) * 2), height

    # If width overflows, then go for fit-to-width mode
    if dimensions[0] > width:
        dimensions = width, int(np.ceil(h * width / float(w) / 2) * 2)
        border = int((height - dimensions[1]) / 2)
        borders[0:2] = [border, border]
    else:
        border = int((width - dimensions[0]) / 2)
        borders[2:4] = [border, border]

    resized = cv2.resize(frame, dimensions, interpolation=inter)
    resized = cv2.copyMakeBorder(resized, borders[0], borders[1], borders[2], borders[3], cv2.BORDER_CONSTANT)
    return resized

# Parse `frame` and return the bitonal bitmap
def parseFrame(frame):
    frame = resizeFrame(frame, 128, 64)
    grayFrame = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
    bitmap = np.digitize(grayFrame, [128])
    return bitmap

# Append `frame` bitmap to `outputFile` according to horizontal mode operation of the OLED display
def writeFrame(frame, outputFile):
    nPages = 8
    pages = [frame[nPages*i:nPages*(i + 1), :] for i in range(0, nPages)]
    for page in pages:
        for col in range(page.shape[1]):
            colList = page[:, col][::-1]
            byte = int(''.join(str(e) for e in colList), 2).to_bytes(1, 'little', signed=False)
            outputFile.write(byte)

video = cv2.VideoCapture("bad-apple.mkv")

# Open the file in binary write mode
outputFile = open("bad-apple.bin", "wb")

sourceFPS = 60
targetFPS = 24
samplingRate = math.floor(sourceFPS / targetFPS)

currentFrame = 0
totalFrames = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
hasFrame, image = video.read()
while hasFrame:
    writeFrame(parseFrame(image), outputFile)
    printProgressBar(currentFrame, totalFrames)

    for i in range(samplingRate):
        hasFrame, image = video.read()

        if not hasFrame:
            break
    currentFrame += samplingRate

video.release()

# Close the file
outputFile.close()
