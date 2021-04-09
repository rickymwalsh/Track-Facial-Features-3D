

function [inlierPoints_M_L, inlierPoints_L, inlierPoints_M_R, inlierPoints_R] = ...
            get_initial_landmarks(videoFrame_M, videoFrame_L, videoFrame_R, featureArea, ...
                                    showPlots)
    % Easier to detect the nose than the eyes => set a lower threshold.
    if strcmp(featureArea, 'Nose')      
        mergeThreshold = 50;
    else 
        mergeThreshold = 200;
    end
    % Create a cascade detector object for the relevant feature area.
    faceDetector = vision.CascadeObjectDetector('ClassificationModel',featureArea, ...
                            'MergeThreshold', mergeThreshold);
    
    % Detect the facial area in the middle camera and create a bounding box.
    bbox = step(faceDetector, rgb2gray(videoFrame_M));

    % Find the Shi-Tomasi corner points within the bounding box.
    % No threshold on MinQuality as we will take only those with matches
    % from more than one camera.
    detected_points_M = detectMinEigenFeatures(rgb2gray(videoFrame_M), 'ROI', bbox,...
                            'MinQuality',0);
                        
    % Track the same points from the other cameras ------------

    % Create the point tracker for each camera (possible to track different points in L and R)
    tracker_L = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);
    tracker_R = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 5);

    % Initialize the point trackers
    points_M = detected_points_M.Location;
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

    % Find epipolar inliers matching between M and L
    inlierPoints_M_L = matchedPoints_M_L(epipolarInliers_L, :);
    inlierPoints_L = matchedPoints_L(epipolarInliers_L, :);
    % Find epipolar inliers matching between M and R
    inlierPoints_M_R = matchedPoints_M_R(epipolarInliers_R, :);
    inlierPoints_R = matchedPoints_R(epipolarInliers_R, :);
    
    if showPlots
        % Draw the returned bounding box around the detected area for camera M.
        videoFrame_M = insertShape(videoFrame_M, 'Rectangle', bbox);
        figure; imshow(videoFrame_M); title('Detected nose');
        
        % Display the initial detected points for camera M.
        figure, imshow(videoFrame_M), hold on, title('Detected features');
        plot(detected_points_M);
        
        % Display inlier matches (M and L)
        figure
        showMatchedFeatures(videoFrame_M, videoFrame_L, inlierPoints_M_L, inlierPoints_L);
        title('Epipolar Inliers - M and L');
        
        % Display inlier matches (M and R)
        figure
        showMatchedFeatures(videoFrame_M, videoFrame_R, inlierPoints_M_R, inlierPoints_R);
        title('Epipolar Inliers - M and R');
    end

end