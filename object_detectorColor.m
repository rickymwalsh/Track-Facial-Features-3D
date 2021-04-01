clc; clear; close all;

%% Detect a Face
% Create a cascade detector object.
facedetector = vision.CascadeObjectDetector();%'ClassificationModel','UpperBody');

% Open a video file
videoReader = vision.VideoFileReader('subject1/proefpersoon 1.1_L.avi');
% Read a video frsame and run the face detector.
videoFrame      = step(videoReader);
[hueChannel,~,~] = rgb2hsv(videoFrame);

bboxFace            = step(facedetector, videoFrame);
%% Identify Facial Features To Track
% Convert the first box into a list of 4 points
% This to track the face all the time (Kanade-Lucas-Tomasi (KLT) algorithm)
bboxFacePoints = bbox2points(bboxFace(1, :));
pointsFace = detectMinEigenFeatures(rgb2gray(videoFrame), 'ROI', bboxFace);

%% Detect Nose from Face Region
noseDetector = vision.CascadeObjectDetector('Nose','MergeThreshold',16);
%Create Image from face region
faceFrame = imcrop(videoFrame,bboxFace(1,:)) ;
%Detect nose in that region
bboxNose            = step(noseDetector , faceFrame);

bboxNose(1,1:2) = bboxNose(1,1:2) + bboxFace(1,1:2);
figure,imshow(videoFrame); hold on
rectangle('Position', bboxFace,'LineWidth',3, 'LineStyle', '-','EdgeColor', 'r');
for i = 1:size(bboxNose,1)
    rectangle('Position', bboxNose(i,:),'LineWidth',2, 'LineStyle', '-','EdgeColor', 'g');
end


%% Tracking Points
% Create a tracker object.
tracker = vision.HistogramBasedTracker;

% Initialize the tracker histogram 
% using the Hue channel pixels from the nose.
initializeObject(tracker, hueChannel, bboxNose(1,:));

% Create a video player object for displaying video frames.
videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame, 2), size(videoFrame, 1)]+30]);



 while ~isDone(videoReader)
    % get the next frame
    videoFrame = step(videoReader);
    
    % RGB -> HSV
    [hueChannel,~,~] = rgb2hsv(videoFrame);
    
    % Track Using the HUE channel data
    bboxFace = step(tracker, hueChannel);
     
    %Insert a bounding box around the object being tracked
    videoOutFace = insertObjectAnnotation(videoFrame, 'rectangle', bboxFace, 'Face'); 

   % videoOutNose = insertObjectAnnotation(videoFrame, 'rectangle', bboxNose, 'Nose');
     % Display the annotated video frame 
    % using the video player object
    step(videoPlayer, videoOutFace);
 end
% Release resources
release(videoFileReader);
release(videoPlayer);
