
function [new_pts] = ...
        translate_coords(pts1, pts2, stereoParams, left_eye_pts1, left_eye_pts2, ...
                            right_eye_pts1, right_eye_pts2, nose_tip_pts1, nose_tip_pts2,...
                            original_nose_tip, check_rotation)
% Function to get the regular world coordinates of selected points from two
% cameras and translate them into the reference coordinate system in
% relation to the facial landmarks.
% Input:
%   pts1, pts2      The points to be converted, one set each from one camera.   
%   stereoParams    The relevant stereoParams for the two cameras (pts1 and pts2)
%   left_eye_pts1 (& 2)   The points for the left eye (observer perspective) from cams 1 (& 2)
%   right_eye_pts1 (&2)   Points for the right eye from cams 1 (& 2).
%   nose_tip_pts1 (&2)    Points at the tip of the nose from cams 1 (& 2).
%   original_nose_tip     The original point of the nose tip in the original 
%                         facial coordinate system.
%   check_rotation        true or false. Whether to check for rotation vs. original.
% Returns:
%   new_pts     The points defined by pts1 and pts2, expressed in the world
%               coordinate system relative to the facial landmarks.
    
    % Get the world coordinates for the facial landmarks.
    left_eye_w = triangulate(left_eye_pts1, left_eye_pts2, stereoParams);                    
    right_eye_w = triangulate(right_eye_pts1, right_eye_pts2, stereoParams);                    
    nose_tip_w = triangulate(nose_tip_pts1, nose_tip_pts2, stereoParams);                    
                        
    % Find the average point location for each area. Multiple points are selected 
    % to ensure they are tracked from frame to frame.   
    if size(left_eye_w,1) > 1 
        left_eye = median(left_eye_w); 
    else left_eye=left_eye_w; 
    end
    if size(right_eye_w,1) > 1 
        right_eye = median(right_eye_w); 
    else right_eye=right_eye_w; 
    end
    if size(nose_tip_w,1) > 1 
        nose_tip = median(nose_tip_w); 
    else nose_tip=nose_tip_w; 
    end
                    
    z0 = (left_eye(3) + right_eye(3))/2;   % New Z=0 position to be the mean Z of the eyes.
   
    pts_world = triangulate(pts1, pts2, stereoParams);    % Translate to world coordinates.

    % Get a vector in the direction of the new x-axis and the x=0 origin.
    x_vec = (right_eye-left_eye)/norm(right_eye-left_eye);
    x0 = (right_eye+left_eye)/2;   % Set new X=0 halfway between left and right eye.
    x0(3) = 0;    % Disregarding the Z-direction when getting this axis for simplicity.
    % The new X coordinates for each point will be the dot product with the unit vector
    % pointing along the X-axis (ignoring Z contribution), after shifting by the x-origin.
    new_pts(:,1) = ([pts_world(:,1:2) zeros(size(pts_world,1),1)] - x0) * x_vec';    
    % The line between the left & right eye defines the X-axis. The
    % distance to this line (ignoring Z coordinates) gives the new Y coordinates.
    new_pts(:,2) = -point_to_line_2D(pts_world, left_eye, right_eye); 
    new_pts(:,3) = z0 - pts_world(:,3);   %Z-axis is the same, but the origin is shifted to the eyes.
    
    % Allow and correct for rotation about the new x-axis by checking the nose_tip location.
    % Rotation matrix calculation taken from: "https://math.stackexchange.com/...
    % 180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d/476311#476311"
    ssc = @(v) [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
    RU = @(A,B) eye(3) + ssc(cross(A,B)) + ...
     ssc(cross(A,B))^2*(1-dot(A,B))/(norm(cross(A,B))^2); % Function to get rotation matrix.
 
    if check_rotation
        % Get the nose_tip coordinates relative to the coordinate system above.
        new_nose(1) = dot(x0 - [nose_tip(1:2) 0], x_vec);
        new_nose(2) = -point_to_line_2D(nose_tip, left_eye, right_eye); 
        new_nose(3) = z0 - nose_tip(3);
        % Check if it is a different location to the original nose tip. If so,
        % get the rotation matrix and apply it to the detected tongue points.
        if  (norm(new_nose(2:3) - original_nose_tip(2:3))> 0.001)
            R=RU([0 original_nose_tip(2) original_nose_tip(3)], [0 new_nose(2) new_nose(3)]);
            R = R/norm(R);   % Normalise the matrix.
            R(1) = 1;        % Rotation about x-axis => preserve x coordinates.
            new_pts = new_pts * R;          % Apply the same rotation to the new points.
        end
    end
end                                                          
                                
function d = point_to_line_2D(pts, v1, v2)
    % Get perpendicular distance from point to a line.
    % pts should be nx2
    % v1 and v2 are vertices on the line (each 1x2)
    % d is a nx1 vector with the orthogonal distances
    pts(:,3) = zeros(size(pts,1),1);        % Set the third column to be zero.
    v1(3) = 0; v2(3) = 0;                   % We're interested only in X and Y here.
    v1 = repmat(v1,size(pts,1),1);
    v2 = repmat(v2,size(pts,1),1);
    a = v1 - v2;
    b = pts - v2;
    d = sqrt(sum(cross(a,b,2).^2,2)) ./ sqrt(sum(a.^2,2));
end