videoReader = VideoReader('subject1/proefpersoon 1.1_R.avi');
videoFrame = readFrame(videoReader);

background = videoFrame;
background_grey = rgb2gray(videoFrame);

figure; imshow(background, []); title('Video Frame');

% Try background subtraction when the tongue is out straight.
out_straight = read(videoReader,250);
out_straight_grey = rgb2gray(out_straight);
figure, imshow(out_straight_grey,[]);

grey_diff_straight = out_straight_grey - background_grey;
rgb_diff_straight = int16(out_straight) - int16(background);
rgb_diff_straight = rescale(rgb_diff_straight,0,255); % Rescale to 0-255 so that it can be interpreted as image.
rgb_diff_straight = uint8(rgb_diff_straight);

figure, imshow(grey_diff_straight, []); title('Grey Diff - Straight Out');
figure, imshow(rgb2gray(rgb_diff_straight) < 110, []); title('RGB Diff - Straight Out');

% Try the same with tongue out to the left.
out_left = read(videoReader,500);
out_left_grey = rgb2gray(out_left);
figure, imshow(out_left_grey,[]);

grey_diff_left = out_left_grey - background_grey;
rgb_diff_left = int16(out_left) - int16(background);
rgb_diff_left = rescale(rgb_diff_left,0,255); % Rescale to 0-255 so that it can be interpreted as image.
rgb_diff_left = uint8(rgb_diff_left);

figure, imshow(grey_diff_left, []); title('Grey Diff - Out Left');
figure, imshow(rgb2gray(rgb_diff_left) < 100, []); title('RGB Diff - Out Left');

%% Try Edge Detector

% Get the edges using Canny and Marr-Hildreth methods.
edges_canny = ut_edge(out_straight_grey(500:700,700:900), 'c', 's',2,'h', [0.1 0.01]);
edges_mh = ut_edge(out_straight_grey(500:700,700:900), 'm', 's',2,'h', [0.05 0.0175]);

figure, imshow(edges_canny, []); title('Canny Edges');
figure, imshow(edges_mh, []); title('Marr-Hildreth Edges');

% Get the edges using Canny and Marr-Hildreth methods.
edges_canny = ut_edge(out_left(500:700,600:900), 'c', 's',2,'h', [0.1 0.01]);
edges_mh = ut_edge(out_left(500:700,600:900), 'm', 's',2,'h', [0.05 0.0175]);

figure, imshow(edges_canny, []); title('Canny Edges - Left');
figure, imshow(edges_mh, []); title('Marr-Hildreth Edges - Left');
