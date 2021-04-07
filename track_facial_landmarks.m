
clc; close all; clear variables;

filenames = ['subject1/proefpersoon 1.1_M.avi'; ...
                'subject1/proefpersoon 1.1_L.avi'; 'subject1/proefpersoon 1.1_R.avi'];
  
videoReader_M = VideoReader(filenames(1,:));
videoFrame_M  = readFrame(videoReader_M);
videoReader_L = VideoReader(filenames(2,:));
videoFrame_L  = readFrame(videoReader_L);
videoReader_R = VideoReader(filenames(3,:));
videoFrame_R  = readFrame(videoReader_R);

% Find the interest points in the relevant facial areas (nose and each eye).
[pts1_M_L, pts1_L, pts1_M_R, pts1_R] = ...
    get_initial_landmarks(videoFrame_M, videoFrame_L, videoFrame_R, 'Nose', false);
[pts2_M_L, pts2_L, pts2_M_R, pts2_R] = ...
    get_initial_landmarks(videoFrame_M, videoFrame_L, videoFrame_R, 'LeftEye', false);
[pts3_M_L, pts3_L, pts3_M_R, pts3_R] = ...
    get_initial_landmarks(videoFrame_M, videoFrame_L, videoFrame_R, 'RightEye', false);

landmark_pts_M_L = [pts1_M_L; pts2_M_L; pts3_M_L];
landmark_pts_M_R = [pts1_M_R; pts2_M_R; pts3_M_R];
landmark_pts_L = [pts1_L; pts2_L; pts3_L];
landmark_pts_R = [pts1_R; pts2_R; pts3_R];

%% Track the matched points separately for each camera.

% Create point trackers.
pointTracker_M_L = vision.PointTracker('MaxBidirectionalError', 2);
pointTracker_M_R = vision.PointTracker('MaxBidirectionalError', 2);
pointTracker_L = vision.PointTracker('MaxBidirectionalError', 2);
pointTracker_R = vision.PointTracker('MaxBidirectionalError', 2);

% Initialize the trackers with the initial point locations and the initial video frames.
initialize(pointTracker_M_L, landmark_pts_M_L, videoFrame_M);
initialize(pointTracker_M_R, landmark_pts_M_R, videoFrame_M);
initialize(pointTracker_L, landmark_pts_L, videoFrame_L);
initialize(pointTracker_R, landmark_pts_R, videoFrame_R);

%% Get the world coordinates of the detected points.

load('stereoParamsLM.mat'); % Load the saved calibration parameters.
load('stereoParamsRM.mat');

% Get the world coordinates in terms of the middle camera.
world_pts_M_L = triangulate(landmark_pts_M_L, landmark_pts_L, stereoParamsLM);
world_pts_M_R = triangulate(landmark_pts_M_R, landmark_pts_R, stereoParamsRM);

% Show the detected points on the middle camera image.
figure, imshow(videoFrame_M); title('Middle Camera with detected & matched points');
axis on
hold on;
% Plot cross at row 100, column 50
plot(landmark_pts_M_L(:,1),landmark_pts_M_L(:,2), 'b+', 'MarkerSize', 5);
plot(landmark_pts_M_R(:,1),landmark_pts_M_R(:,2), 'r+', 'MarkerSize', 5);
legend('Left Camera', 'Right Camera');

figure, scatter(world_pts_M_L(:,1), -world_pts_M_L(:,2), 'blue')
hold on 
scatter(world_pts_M_R(:,1), -world_pts_M_R(:,2), 'red')
title('Y vs. X world coordinates of matched points');
xlabel('X');ylabel('Y');
legend('Left Camera', 'Right Camera');

% Plot Z vs. X
figure, scatter(world_pts_M_L(:,1), world_pts_M_L(:,3), 'blue')
hold on 
scatter(world_pts_M_R(:,1), world_pts_M_R(:,3), 'red')
title('Z vs. X world coordinates of matched points');
xlabel('X'); ylabel('Z');
legend('Left Camera', 'Right Camera');


%% Play video and track the points.
% Create video players for each camera.
videoPlayer_M  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame_M, 2), size(videoFrame_M, 1)]+30]);
videoPlayer_L  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame_L, 2), size(videoFrame_L, 1)]+30]);
videoPlayer_R  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame_R, 2), size(videoFrame_R, 1)]+30]);

while hasFrame(videoReader_M)
    % get the next frame
    videoFrame_M = readFrame(videoReader_M);
    videoFrame_L = readFrame(videoReader_L);
    videoFrame_R = readFrame(videoReader_R);
    
    % Track the points. 
    [matchedPoints_M_L, isFound_M_L] = step(pointTracker_M_L, videoFrame_M);
    [matchedPoints_M_R, isFound_M_R] = step(pointTracker_M_R, videoFrame_M);
    [matchedPoints_L, isFound_L] = step(pointTracker_L, videoFrame_L);
    [matchedPoints_R, isFound_R] = step(pointTracker_R, videoFrame_R);
    
    % Take only the points detected in both of the relevant images.
    visiblePoints_M_L = matchedPoints_M_L(isFound_M_L & isFound_L, :);
    visiblePoints_M_R = matchedPoints_M_R(isFound_M_R & isFound_R, :);
    visiblePoints_L = matchedPoints_L(isFound_L & isFound_M_L, :);
    visiblePoints_R = matchedPoints_R(isFound_R & isFound_M_R, :);
    
    % Use RANSAC to detect outliers and inliers.
    [~, epipolarInliers_L] = estimateFundamentalMatrix(...
        visiblePoints_M_L, visiblePoints_L, 'Method', 'RANSAC', 'NumTrials', 500,...
        'DistanceType', 'Algebraic','DistanceThreshold',0.01);
    [~, epipolarInliers_R] = estimateFundamentalMatrix(...
        visiblePoints_M_R, visiblePoints_R, 'Method', 'RANSAC', 'NumTrials', 500,...
        'DistanceType', 'Algebraic','DistanceThreshold',0.01);
       
    % Draw the inliers on the frames.
    videoFrame_M = insertMarker(videoFrame_M, visiblePoints_M_L(epipolarInliers_L,:), '+', ...
    'Color', 'blue');  
    videoFrame_L = insertMarker(videoFrame_L, visiblePoints_L(epipolarInliers_L,:), '+', ...
    'Color', 'blue');  
    videoFrame_M = insertMarker(videoFrame_M, visiblePoints_M_R(epipolarInliers_R,:), '+', ...
    'Color', 'red');  
    videoFrame_R = insertMarker(videoFrame_R, visiblePoints_R(epipolarInliers_R,:), '+', ...
    'Color', 'red');  
    
    % Display the annotated video frame using the video player object
    step(videoPlayer_M, videoFrame_M);
    step(videoPlayer_L, videoFrame_L);
    step(videoPlayer_R, videoFrame_R);
end

% Clean up
release(videoPlayer_M);
release(videoPlayer_L);
release(videoPlayer_R);



