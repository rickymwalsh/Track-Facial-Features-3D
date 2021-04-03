videoReader_R = VideoReader('subject1/proefpersoon 1.1_R.avi');

% Get a video frame with the tongue out to the left.
out_left = read(videoReader_R,500);
out_left_grey = rgb2gray(out_left);
figure, imshow(out_left);

%% Cluster colours within the face box.
% Rough box for face for testing purposes - can replace with proper
% bounding box if experiment works.
out_left_face = out_left(89:622,612:964,:);
figure, imshow(out_left_face); title('Rough box for face');
out_left_face_grey = rgb2gray(out_left_face);

% Get the LAB representation of the image.
lab_im = rgb2lab(out_left_face);
ab = lab_im(:,:,2:3); % Extracting just the AB part from the LAB image.
ab = im2single(ab); 
nColors = 6;
% Cluster similar colours together.
pixel_labels = imsegkmeans(ab,nColors,'NumAttempts',3); % repeat 3 times to avoid local minima
% figure, imshow(pixel_labels,[]); title('Image Labeled by Cluster Index');

% Plot only the relevant colour region.
mask1 = pixel_labels==4;    % Find which pixels fall into the relevant cluster.
cluster1 = out_left_face .* uint8(mask1);  % Zero all pixels but the relevant colour ones.
highlighted_cluster = max(out_left_face_grey, uint8(mask1)*256); 
figure, imshow(highlighted_cluster); title('Highlighted Cluster (Original Image)');

%% Find distance between mean/median cluster colour and other pixels.

% Calculate the mean A and B values in the relevant cluster. (Need to take
% nonzeros() as the cluster1 variable holds the whole image with pixels not
% in the cluster set to zero.
a_mean = mean(nonzeros(cluster1(:,:,2)));
b_mean = mean(nonzeros(cluster1(:,:,3)));

clust_mean=a_mean; clust_mean(:,:,2)=b_mean;   % Create a 3D array to hold the mean.

% Calculate the Euclidean distance of each pixel to the cluster mean.
d = sqrt(sum((ab - clust_mean).^2, 3));  

% Show the distance of each pixel from the relevant colour. Dark means close.
figure, imshow(d, []); 
figure, imshow(d < 60, []);  % Threshold the points within a certain distance.

% Compare the colour difference for another image.
out_up = read(videoReader_R,600);
out_up_face = out_up(89:622,612:964,:);  % Rough bounding box for face.
figure, imshow(out_up_face);

% Get the AB colour representation as above, and get the Euclidean distance. 
lab_im_up = rgb2lab(out_up_face);
ab_up = lab_im_up(:,:,2:3);
ab_up = im2single(ab_up);
d_up = sqrt(sum((ab_up - clust_mean).^2, 3));

figure, imshow(d_up, []); title('Distance to relevant colour - darker=closer');
figure, imshow(d_up < 60, []); ('Regions close to relevant colour'); %Threshold

%% Apply to video.
% Identify the regions close to the relevant colour for each video frame.
% videoPlayer_R = vision.VideoPlayer();   % Create videoPlayer
videoWriter = VideoWriter('thresholded_colour.avi');
open(videoWriter);

while hasFrame(videoReader_R)
      frame_R = readFrame(videoReader_R);
      lab_im = rgb2lab(frame_R);             % Get the AB representation of the frame.
      ab = lab_im(:,:,2:3);
      ab = im2single(ab);

      d = sqrt(sum((ab - clust_mean).^2,3)); % Euclidean distance.

      out_R = frame_R .* uint8(d < 60);  % Threshold the video frame.
%       videoPlayer_R(out_R);              % Play the frame.
      writeVideo(videoWriter, out_R);
end

close(videoWriter);
% release(videoPlayer_R)




