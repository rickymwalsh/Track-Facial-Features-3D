

videoReader = VideoReader('subject1/proefpersoon 1.1_L.avi');
videoFrame = readFrame(videoReader);
% videoFrame      = read(videoReader,250);
figure; imshow(videoFrame); title('Video Frame');

% imshow(, [])

[xi, yi] = getpts();

pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
initialize(pointTracker, [xi yi], videoFrame);

videoPlayer  = vision.VideoPlayer('Position',...
    [100 100 [size(videoFrame, 2), size(videoFrame, 1)]+30]);

while hasFrame(videoReader)
    % get the next frame
    videoFrame = readFrame(videoReader);

    % Track the points. Note that some points may be lost.
    [points, isFound] = step(pointTracker, videoFrame);
    visiblePoints = points(isFound, :);
    
    if size(visiblePoints, 1) >= 2 % need at least 2 points
        % Display tracked points
        videoFrame = insertMarker(videoFrame, visiblePoints, '+', ...
            'Color', 'white');            
    end
    % Display the annotated video frame using the video player object
    step(videoPlayer, videoFrame);
end

% Clean up
release(videoPlayer);
