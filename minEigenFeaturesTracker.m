videoReader_R = VideoReader('subject1/proefpersoon 1.1_R.avi');
videoPlayer_R = vision.VideoPlayer();
objectFrame_R = read(videoReader_R, 250);

videoReader_M = VideoReader('subject1/proefpersoon 1.1_M.avi');
videoPlayer_M = vision.VideoPlayer();
objectFrame_M = read(videoReader_M, 250);

videoReader_L = VideoReader('subject1/proefpersoon 1.1_L.avi');
videoPlayer_L = vision.VideoPlayer();
objectFrame_L = read(videoReader_L, 250);

figure; imshow(objectFrame_R);
objectRegion_R=round(getPosition(imrect));
figure; imshow(objectFrame_M);
objectRegion_M=round(getPosition(imrect));
figure; imshow(objectFrame_L);
objectRegion_L=round(getPosition(imrect));


objectImage_R = insertShape(objectFrame_R,'Rectangle',objectRegion_R,'Color','red');
figure;
imshow(objectImage_R);
title('Red box shows object region');

points_R = detectMinEigenFeatures(im2gray(objectFrame_R),'ROI',objectRegion_R);

pointImage_R = insertMarker(objectFrame_R,points_R.Location,'+','Color','white');
figure; imshow(pointImage_R); title('Detected interest points');

tracker_R = vision.PointTracker('MaxBidirectionalError',1);
initialize(tracker_R,points_R.Location,objectFrame_R);

objectImage_M = insertShape(objectFrame_M,'Rectangle',objectRegion_M,'Color','red');
figure;
imshow(objectImage_M);
title('Red box shows object region');

points_M = detectMinEigenFeatures(im2gray(objectFrame_M),'ROI',objectRegion_M);

pointImage_M = insertMarker(objectFrame_M,points_M.Location,'+','Color','white');
figure; imshow(pointImage_M); title('Detected interest points');

tracker_M = vision.PointTracker('MaxBidirectionalError',1);
initialize(tracker_M,points_M.Location,objectFrame_M);

objectImage_L = insertShape(objectFrame_L,'Rectangle',objectRegion_L,'Color','red');
figure;
imshow(objectImage_L);
title('Red box shows object region');

points_L = detectMinEigenFeatures(im2gray(objectFrame_L),'ROI',objectRegion_L);

pointImage_L = insertMarker(objectFrame_L,points_L.Location,'+','Color','white');
figure; imshow(pointImage_L); title('Detected interest points');

tracker_L = vision.PointTracker('MaxBidirectionalError',1);
initialize(tracker_L,points_L.Location,objectFrame_L);

%% Play video.

while hasFrame(videoReader_R)
      frame_R = readFrame(videoReader_R);
      [points_R,validity_R] = tracker_R(frame_R);
      out_R = insertMarker(frame_R,points_R(validity_R, :),'+');
      videoPlayer_R(out_R);
      
      frame_M = readFrame(videoReader_M);
      [points_M,validity_M] = tracker_M(frame_M);
      out_M = insertMarker(frame_M,points_M(validity_M, :),'+');
      videoPlayer_M(out_M);	
      
      frame_L = readFrame(videoReader_L);
      [points_L,validity_L] = tracker_L(frame_L);
      out_L = insertMarker(frame_L,points_L(validity_L, :),'+');
      videoPlayer_L(out_L);	
end