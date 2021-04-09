%% Initialise, create video readers, players and initial frames.
clc; close all; clear variables;

filenames = ['subject1/proefpersoon 1.1_M.avi'; 'subject1/proefpersoon 1.1_R.avi';
                    'subject1/proefpersoon 1.1_L.avi'];
    
videoReader_M = VideoReader(filenames(1,:));
videoPlayer_M = vision.VideoPlayer();
objectFrame_M = read(videoReader_M, 250);

videoReader_R = VideoReader(filenames(2,:));
videoPlayer_R = vision.VideoPlayer();
objectFrame_R = read(videoReader_R, 250);

videoReader_L = VideoReader(filenames(3,:));
videoPlayer_L = vision.VideoPlayer();
objectFrame_L = read(videoReader_L, 250);

%% Get the initial points to track in the middle camera.

figure; imshow(objectFrame_M);
objectRegion_M=round(getPosition(imrect));   % User selects the rectangle of interest.
%width = objectRegion_M[3];
%height = objectRegion_M[4];

points_M = detectMinEigenFeatures(im2gray(objectFrame_M),'ROI',objectRegion_M,...
                                    'MinQuality',0.001);

% Initialise point tracker for the middle camera - position should not
% change too much from frame to frame => PyramidLevels to reduce computation time.
tracker_M = vision.PointTracker('MaxBidirectionalError',1,'NumPyramidLevels',2);
points_M = points_M.Location;

% Initialize the tracker with the initial point locations and the initial
initialize(tracker_M,points_M,objectFrame_M);

oldPoints = points_M;
%% Play video.
videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(objectFrame_M, 2), size(objectFrame_M, 1)]+30]);

% Load the pairs of extrinsic parameter matrices.
load("stereoParamsLM.mat"); load("stereoParamsRM.mat");

% Trackers for tracking from middle to left & right cameras. Allow higher
% pyramid levels since position can be shifted more.
tracker_R = vision.PointTracker('MaxBidirectionalError',2.5,'NumPyramidLevels',6);
tracker_L = vision.PointTracker('MaxBidirectionalError',2.5,'NumPyramidLevels',6);

figure(); hold on;   % Create a figure to hold the world coordinates plots.
title('Y vs. X world coordinates of tracked tongue points');
xlabel('X'); ylabel('Y');

while hasFrame(videoReader_M)
          
    frame_M = readFrame(videoReader_M);
    % Track the points. Note that some points may be lost.
    [points_M, isFound] = step(tracker_M, frame_M);
    visiblePoints = points_M(isFound, :);
    oldInliers = oldPoints(isFound, :);

    if size(visiblePoints, 1) <= 10
        m1 =visiblePoints(:,1);
        m2 =visiblePoints(:,2);

        mediaX = round(median(m1));
        mediaY = round(median(m2));
        objectRegion_M(1) = mediaX - 27;
        objectRegion_M(2) = mediaY - 27;
        points_M = detectMinEigenFeatures(im2gray(frame_M),'ROI',objectRegion_M,...
                                   'MinQuality',0.001);

        tracker_M = vision.PointTracker('MaxBidirectionalError',1,'NumPyramidLevels',2);
        points_M = points_M.Location;

        initialize(tracker_M,points_M,frame_M);
        [points_M, isFound] = step(tracker_M, frame_M);

        visiblePoints = points_M(isFound, :);

        oldInliers = visiblePoints;
        %pause(4);
    end

    % Estimate the geometric transformation between the old points
    % and the new points and eliminate outliers
    [xform, inlierIdx] = estimateGeometricTransform2D(...
    oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
    oldInliers    = oldInliers(inlierIdx, :);
    visiblePoints = visiblePoints(inlierIdx, :);

    % Display tracked points
    frame_M = insertMarker(frame_M, visiblePoints, '+', ...
                    'Color', 'white');

    % Track the points from the middle camera to the right camera.
    release(tracker_R);
    initialize(tracker_R, visiblePoints, frame_M);
    frame_R = readFrame(videoReader_R);
    [points_R,validity_R] = tracker_R(frame_R);
%     out_R = insertMarker(frame_R,points_R(validity_R, :),'+');
%     videoPlayer_R(out_R);

    % Track the points from the middle camera to the left camera.
    release(tracker_L);
    initialize(tracker_L, visiblePoints, frame_M);
    frame_L = readFrame(videoReader_L);
    [points_L,validity_L] = tracker_L(frame_L);
    
    world_pts_M_L = triangulate(visiblePoints(validity_L,:), points_L(validity_L, :),...
                            stereoParamsLM);
    world_pts_M_R = triangulate(visiblePoints(validity_R,:), points_R(validity_R, :),...
                            stereoParamsRM);

    scatter(world_pts_M_L(:,1), -world_pts_M_L(:,2),16,'blue','filled')      
    scatter(world_pts_M_R(:,1), -world_pts_M_R(:,2),16, 'red','filled')    

    % Reset the points
    oldPoints = visiblePoints;
    setPoints(tracker_M, oldPoints);  
    % Display the annotated video frame using the video player object
    step(videoPlayer, frame_M);
end