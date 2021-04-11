%% Initialise, create video readers, players and initial frames.
clc; close all; clear variables;

filenames = ['subject4/proefpersoon 4_M.avi'; 'subject4/proefpersoon 4_R.avi';
                    'subject4/proefpersoon 4_L.avi'];
% Load the pairs of extrinsic parameter matrices.
load("stereoParamsLM.mat"); load("stereoParamsRM.mat");
    
videoReader_M = VideoReader(filenames(1,:));
videoPlayer_M = vision.VideoPlayer();
objectFrame_M = read(videoReader_M, 350);

videoReader_R = VideoReader(filenames(2,:));
videoPlayer_R = vision.VideoPlayer();
objectFrame_R = read(videoReader_R, 350);

videoReader_L = VideoReader(filenames(3,:));
videoPlayer_L = vision.VideoPlayer();
objectFrame_L = read(videoReader_L, 350);

%% Get the facial landmarks to create a coordinate system.

figure; imshow(objectFrame_M); title('Select Points for Left Eye');
[xi, yi] = getpts();            % Select points for the outer edge of left eye.
facePoints_M = [xi yi];
loc = repmat("Left Eye", size(xi)); % Vector to track which region the points correspond to.

figure; imshow(objectFrame_M); title('Select Points for Right Eye');
[xi, yi] = getpts();            % Select points for the outer edge of right eye.
facePoints_M = [facePoints_M; xi yi];   % Append the new points.
loc = [loc; repmat("Right Eye", size(xi))];   % Append the new region.       

figure; imshow(objectFrame_M); title('Select Points for Nose Tip');
[xi, yi] = getpts();            % Select points for the outer edge of nose tip.
facePoints_M = [facePoints_M; xi yi];   % Append the new points.
loc = [loc; repmat("Nose", size(xi))];        % Append the new region.

% Create the point tracker for each camera (possible to track different points in L and R)
faceTracker_L = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);
faceTracker_R = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);
faceTracker_M = vision.PointTracker('MaxBidirectionalError', 1, ...
                        'NumPyramidLevels', 2); % Less likely to change position => 
                                            % lower pyramid levels to save some computation.                                            

% Initialize the point trackers
initialize(faceTracker_L, facePoints_M, objectFrame_M);
initialize(faceTracker_R, facePoints_M, objectFrame_M);
initialize(faceTracker_M, facePoints_M, objectFrame_M);

% Find the points in the L and R camera frames.
[facePoints_L, validIdx_L] = step(faceTracker_L, objectFrame_L);
[facePoints_R, validIdx_R] = step(faceTracker_R, objectFrame_R);
% Extract the valid matches.
facePoints_M = facePoints_M(validIdx_L, :);
facePoints_L = facePoints_L(validIdx_L, :);
% facePoints_R = facePoints_R(validIdx_R & validIdx_L, :);

% Get the point indexes for Left Eye, Right Eye, etc. for the Left and Right cameras.
le_id = (loc(validIdx_L)=="Left Eye");    
re_id = (loc(validIdx_L)=="Right Eye");   
n_id  = (loc(validIdx_L)=="Nose");       

newFacePts = translate_coords(facePoints_M, facePoints_L, ...
        stereoParamsLM, facePoints_M(le_id,:), facePoints_L(le_id,:),...
        facePoints_M(re_id,:), facePoints_L(re_id,:), [0 0], [0 0], [0 0 0], false);
    
% Save original nose position to compare to subsequent facial coordinate systems.
if size(newFacePts(n_id,:),1) > 1
   orig_nose = median(newFacePts(n_id,:));
else, orig_nose = newFacePts(n_id,:);
end

%% Get the initial points to track in the middle camera.

figure; imshow(objectFrame_M); title('Draw rectangle around tongue tip');
objectRegion_M=round(getPosition(imrect));   % User selects the rectangle of interest.

tonguePoints_M = detectMinEigenFeatures(im2gray(objectFrame_M),'ROI',objectRegion_M,...
                                    'MinQuality',0.001); % Reduce Quality to get more pts.

% Initialise point tracker for the middle camera - position should not
% change too much from frame to frame => PyramidLevels to reduce computation time.
tracker_M = vision.PointTracker('MaxBidirectionalError',1, 'NumPyramidLevels',3);
tonguePoints_M = tonguePoints_M.Location;

% Initialize the tracker with the initial point locations.
initialize(tracker_M, tonguePoints_M, objectFrame_M);

oldPoints = tonguePoints_M;

%% Play video.
videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(objectFrame_M, 2), size(objectFrame_M, 1)]+30]);

% Trackers for tracking from middle to left & right cameras. Allow higher
% pyramid levels since position can be shifted more.
tracker_R = vision.PointTracker('MaxBidirectionalError',2,'NumPyramidLevels',5);
tracker_L = vision.PointTracker('MaxBidirectionalError',2,'NumPyramidLevels',5);

figure(); hold on;   % Create a figure to hold the world coordinates plots.
title('Y vs. X world coordinates of tracked tongue points');
xlabel('X'); ylabel('Y');

saved_pts_L=[]; saved_pts_R=[];             % Arrays to hold the tongue points.

while hasFrame(videoReader_M)
          
    frame_M = readFrame(videoReader_M);
    % Track the points. Note that some points may be lost.
    [points_M, isFound] = step(tracker_M, frame_M);
    visiblePoints = points_M(isFound, :);
    oldInliers = oldPoints(isFound, :);

    % Recapture interest points if they drop below 10.
    if size(visiblePoints, 1) <= 10 
        % If num of points too low, manually re-select rectangle.
        if size(visiblePoints, 1) <= 1 
            figure; imshow(frame_M); title('Draw rectangle around tongue tip');
            objectRegion_M=round(getPosition(imrect));   % User selects the rectangle of interest.
        else
            % Get the current motion and assume it will partly continue.
            shift = median(visiblePoints) - oldCentre;
            newCentre = median(visiblePoints) + shift/2;  
            % The new rectangle will have the same size as the old one.
            objectRegion_M(1:2) = newCentre - objectRegion_M(3:4)/2;
        end
        points_M = detectMinEigenFeatures(im2gray(frame_M),'ROI',objectRegion_M,...
                                   'MinQuality',0.001);

        setPoints(tracker_M, points_M.Location);  
        visiblePoints = points_M.Location;
    else
        % Estimate the geometric transformation between the old points
        % and the new points and eliminate outliers
        [xform, inlierIdx] = estimateGeometricTransform2D(...
                        oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
        oldInliers    = oldInliers(inlierIdx, :);
        visiblePoints = visiblePoints(inlierIdx, :);
    end

    % Display tracked points
    frame_M = insertMarker(frame_M, visiblePoints, '+', 'Color', 'white');

    % Track the points from the middle camera to the right camera.
    release(tracker_R);
    initialize(tracker_R, visiblePoints, frame_M);
    frame_R = readFrame(videoReader_R);
    [points_R,validIdx_tongue_R] = tracker_R(frame_R);
%     out_R = insertMarker(frame_R,points_R(validity_R, :),'+');
%     videoPlayer_R(out_R);

    % Track the points from the middle camera to the left camera.
    release(tracker_L);
    initialize(tracker_L, visiblePoints, frame_M);
    frame_L = readFrame(videoReader_L);
    [points_L,validIdx_tongue_L] = tracker_L(frame_L);
    
    % Track the facial landmarks.
    [facePts_L, validIdx_L] = step(faceTracker_L, frame_L);
    [facePts_R, validIdx_R] = step(faceTracker_R, frame_R);
    [facePts_M, validIdx_M] = step(faceTracker_M, frame_M);
    % Get the point indexes for Left Eye, Right Eye, etc. for the Left and Middle cameras.
    le_id = (loc(validIdx_L & validIdx_M) == "Left Eye");    
    re_id = (loc(validIdx_L & validIdx_M) == "Right Eye");   
    n_id  = (loc(validIdx_L & validIdx_M) == "Nose");   
    
    % Check that there is at least one point for the tongue and facial landmarks.
    if min([max(le_id), max(re_id), max(n_id), max(validIdx_tongue_L)]) > 0  
        tongue_pts_L = translate_coords( visiblePoints(validIdx_tongue_L,:), ...
            points_L(validIdx_tongue_L, :), stereoParamsLM, facePts_M(le_id,:),...
            facePts_L(le_id,:), facePts_M(re_id,:),facePts_L(re_id,:), ...
            facePts_M(n_id,:), facePts_L(n_id,:), orig_nose, false);
        % Plot the X, Y coordinates of the points.
        scatter(tongue_pts_L(:,1), tongue_pts_L(:,2),16,'blue','filled')      
        saved_pts_L = [saved_pts_L; tongue_pts_L]; % Keep a record of past points.
    end
    
    % Same procedure as above but for the middle and right cameras.
    % Get the point indexes for Left Eye, Right Eye, etc. for the Left and Right cameras.
    le_id = (loc(validIdx_M & validIdx_R) == "Left Eye");    
    re_id = (loc(validIdx_M & validIdx_R) == "Right Eye");   
    n_id  = (loc(validIdx_M & validIdx_R) == "Nose");  
    
    % Check that there is at least one point for the tongue and facial landmarks.
    if min([max(le_id), max(re_id), max(n_id), max(validIdx_tongue_R)]) > 0  
        tongue_pts_R = translate_coords( visiblePoints(validIdx_tongue_R,:), ...
            points_R(validIdx_tongue_R, :), stereoParamsRM, facePts_M(le_id,:),...
            facePts_R(le_id,:), facePts_M(re_id,:),facePts_R(re_id,:), ...
            facePts_M(n_id,:), facePts_R(n_id,:), orig_nose, true);
        % Plot the X, Y coordinates of the points.
        scatter(tongue_pts_R(:,1), tongue_pts_R(:,2),16,'red','filled')      
        saved_pts_R = [saved_pts_R; tongue_pts_R]; % Keep a record of past points.
    end
    % Reset the points
    oldPoints = visiblePoints;
    setPoints(tracker_M, oldPoints);  
    oldCentre = median(visiblePoints);
    % Display the annotated video frame using the video player object
    step(videoPlayer, frame_M);
end

release(videoPlayer);