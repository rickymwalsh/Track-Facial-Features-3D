
clc; close all; clear variables;

filenames = ['subject1/proefpersoon 1.1_M.avi'; ...
                'subject1/proefpersoon 1.1_L.avi'; 'subject1/proefpersoon 1.1_R.avi'];
  
videoReader_M = VideoReader(filenames(1,:));
videoFrame_M  = readFrame(videoReader_M);
videoReader_L = VideoReader(filenames(2,:));
videoFrame_L  = readFrame(videoReader_L);
videoReader_R = VideoReader(filenames(3,:));
videoFrame_R  = readFrame(videoReader_R);

figure; imshow(videoFrame_M); 
title('First Video Frame - Middle Camera');

[xi, yi] = getpts();
points_M = [xi yi];

% Create the point tracker for each camera (possible to track different points in L and R)
tracker_L = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);
tracker_R = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);

% Initialize the point trackers
initialize(tracker_L, points_M, videoFrame_M);
initialize(tracker_R, points_M, videoFrame_M);

% Find the points in the L and R cameras.
[points_L, validIdx_L] = step(tracker_L, videoFrame_L);
[points_R, validIdx_R] = step(tracker_R, videoFrame_R);
% Extract the valid matches.
matchedPoints_M_L = points_M(validIdx_L, :);
matchedPoints_L = points_L(validIdx_L, :);
matchedPoints_M_R = points_M(validIdx_R, :);
matchedPoints_R = points_R(validIdx_R, :);

% Use RANSAC to find inliers.
[~, epipolarInliers_L] = estimateFundamentalMatrix(...
  matchedPoints_M_L, matchedPoints_L, 'Method', 'RANSAC', 'NumTrials', 10000);
[~, epipolarInliers_R] = estimateFundamentalMatrix(...
  matchedPoints_M_R, matchedPoints_R, 'Method', 'RANSAC', 'NumTrials', 10000);

inliers_M_L = matchedPoints_M_L(epipolarInliers_L, :);
inliers_M_R = matchedPoints_M_R(epipolarInliers_R, :);

figure, imshow(videoFrame_M); title('Middle Camera with detected & matched points');
axis on
hold on;
% Plot cross at row 100, column 50
plot(inliers_M_L(:,1),inliers_M_L(:,2), 'b+', 'MarkerSize', 5);
plot(inliers_M_R(:,1),inliers_M_R(:,2), 'ro', 'MarkerSize', 5);
legend('Left Camera', 'Right Camera');


pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
initialize(pointTracker, inliers_M_L, videoFrame_M);

videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame_M, 2), size(videoFrame_M, 1)]+30]);

while hasFrame(videoReader_M)
    % get the next frame
    videoFrame_M = readFrame(videoReader_M);

    % Track the points. Note that some points may be lost.
    [points, isFound] = step(pointTracker, videoFrame_M);
    visiblePoints = points(isFound, :);
    
    if size(visiblePoints, 1) >= 2 % need at least 2 points
        % Display tracked points
        videoFrame_M = insertMarker(videoFrame_M, visiblePoints, '+', ...
            'Color', 'white');            
    end
    % Display the annotated video frame using the video player object
    step(videoPlayer, videoFrame_M);
end

% Clean up
release(videoPlayer);
