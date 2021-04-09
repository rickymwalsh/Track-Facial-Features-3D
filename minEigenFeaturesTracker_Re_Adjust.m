clc; close all; clear variables;


videoReader_M = VideoReader('subject1/proefpersoon 1.1_M.avi');
videoPlayer_M = vision.VideoPlayer();
objectFrame_M = read(videoReader_M, 250);

figure; imshow(objectFrame_M);
objectRegion_M=round(getPosition(imrect));
%width = objectRegion_M[3];
%height = objectRegion_M[4];

objectImage_M = insertShape(objectFrame_M,'Rectangle',objectRegion_M,'Color','red');
figure;
imshow(objectImage_M);
title('Red box shows object region');

points_M = detectMinEigenFeatures(im2gray(objectFrame_M),'ROI',objectRegion_M);

tracker_M = vision.PointTracker('MaxBidirectionalError',1);
points_M = points_M.Location;

% Initialize the tracker with the initial point locations and the initial
initialize(tracker_M,points_M,objectFrame_M);


oldPoints = points_M;
%% Play video.
videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(objectFrame_M, 2), size(objectFrame_M, 1)]+30]);

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
          points_M = detectMinEigenFeatures(im2gray(frame_M),'ROI',objectRegion_M);

          tracker_M = vision.PointTracker('MaxBidirectionalError',1);
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
        
        % Apply the transformation to the bounding box points
    %    bboxPoints = transformPointsForward(xform, bboxPoints);
                
        % Insert a bounding box around the object being tracked
       % bboxPolygon = reshape(bboxPoints', 1, []);
       % videoFrame = insertShape(videoFrame, 'Polygon', bboxPoints, ...
       %     'LineWidth', 2);
                
        % Display tracked points
        frame_M = insertMarker(frame_M, visiblePoints, '+', ...
            'Color', 'white');       
        
        % Reset the points
        oldPoints = visiblePoints;
        setPoints(tracker_M, oldPoints);  
    % Display the annotated video frame using the video player object
    step(videoPlayer, frame_M);
end