clc; clear; close all;

%% Read Files
% Open a video file
videoReader = vision.VideoFileReader('subject1/proefpersoon 1.1_L.avi', 'VideoOutputDataType', 'uint8');
videoFrame = step(videoReader);

%% Detect Mouth
noseDetector = vision.CascadeObjectDetector('Mouth','MergeThreshold', 300); %Nose','MergeThreshold',16);
%Detect Mouth
bboxMouth = step(noseDetector , videoFrame);


%% Tracking Points
% Convert the first box into a list of 4 points
% This is needed to be able to visualize the rotation of the object.
bboxPoints = bbox2points(bboxMouth(1, :));

points = detectMinEigenFeatures(rgb2gray(videoFrame), 'ROI', bboxMouth);
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
% Initialize the tracker with the initial point locations and the initial
% video frame.
points = points.Location;
initialize(pointTracker, points, videoFrame);

videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame, 2), size(videoFrame, 1)]+30]);

oldPoints = points;

while ~isDone(videoReader)
    % get the next frame
    videoFrame = step(videoReader);

    % Track the points. Note that some points may be lost.
    [points, isFound] = step(pointTracker, videoFrame);
    visiblePoints = points(isFound, :);
    oldInliers = oldPoints(isFound, :);
    
    if size(visiblePoints, 1) >= 2 % need at least 2 points
        
        % Estimate the geometric transformation between the old points
        % and the new points and eliminate outliers
        [xform, inlierIdx] = estimateGeometricTransform2D(...
            oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
        oldInliers    = oldInliers(inlierIdx, :);
        visiblePoints = visiblePoints(inlierIdx, :);
        
        % Apply the transformation to the bounding box points
        bboxPoints = transformPointsForward(xform, bboxPoints);
                
        % Insert a bounding box around the object being tracked
        bboxPolygon = reshape(bboxPoints', 1, []);
        videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, ...
            'LineWidth', 2);
                
        % Display tracked points
        videoFrame = insertMarker(videoFrame, visiblePoints, '+', ...
            'Color', 'white');       
        
        % Reset the points
        oldPoints = visiblePoints;
        setPoints(pointTracker, oldPoints);        
    end
    
    % Display the annotated video frame using the video player object
    step(videoPlayer, videoFrame);
end

% Clean up
release(videoPlayer);
