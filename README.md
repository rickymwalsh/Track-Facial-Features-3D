# Track-Facial-Features-3D

#### Statement of the problem
To measure the range of motion, patients are asked to move their tongue to standardized, extreme positions, left, right, forward, downward and upward. A triple camera system is used to measure the 3D positions of the tongue tip. Of course, to compare these positions, pre- and post-treatment, the positions should be expressed with reference to a fixed, well-defined coordinate system that is attached to the head. How to derive these measurements from the recorded triple videos? 

#### Assignment 
Develop and test a method that is able to track the tip of the tongue and some facial landmarks so as to find the 3D positions of these points. Using these facial landmarks, define a 3D reference coordinate system that is attached to the face. Express the 3D position of the tongue tip in that coordinate system. Evaluate the method.

#### Overview of Scripts
1. The cameras are first calibrated with ``calibrate_all.m``, yielding stereo parameters for the two stereo pairs used, Left-Middle and Right-Middle. These parameters are stored in ``stereoParamsLM.mat`` and ``stereoParamsRM.mat``
2. The objective is to pinpoint the location in 3D space at any time during the video. A coordinate reference system is created initially using the position of the nose and eyes. Thus if the head moves tilts during the experiment, the observed points of the tongue need to be transformed back to the original coordinate system. We wrote a function for this in ``translate_coords.m``.
3. The process of tracking & recording results during the video is captured in the ``tongue_readjust_multicamera.m`` script. This includes initialising keypoints and tracking them frame by frame.
4. Finally, we have wrapped this process in a Matlab app ``TongueTrackerApp2.mlapp`` in order to demo the functionality while watching and interacting with the video. Here, you can select initial points of interest, play & pause the video, and intervene if some of the tracked points are lost during the video.
