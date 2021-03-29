% Create ImageSets for each set of calibration images.
leftCalImages = imageSet('Calibratie 1/calibrationLeft/*.jpg')
middleCalImages = imageSet('Calibratie 1/calibrationMiddle/*.jpg');
rightCalImges = imageSet('Calibratie 1/calibrationRight/*.jpg');
% Extract the filenames.
leftCalFileNames = leftCalImages.ImageLocation;
middleCalFileNames = middleCalImages.ImageLocation;
rightCalFileNames = rightCalImages.ImageLocation;

% Find the checkerboard points in each image.
[imagePoints,boardSize,imagesUsed] = detectCheckerboardPoints(rightCalFileNames);
[imagePoints,boardSize,imagesUsed] = detectCheckerboardPoints(rightCalFileNames);
[imagePoints,boardSize,imagesUsed] = detectCheckerboardPoints(rightCalFileNames);