
% ** Not working yet **

function [new_pts] = ...
        translate_coords(pts1, pts2, stereoParams, left_eye_pts1, left_eye_pts2, ...
                            right_eye_pts1, right_eye_pts2, nose_tip_pts1, nose_tip_pts2)
% Function to get the regular world coordinates of selected points from two
% cameras and translate them into the reference coordinate system in
% relation to the facial landmarks.
    
    % Get the world coordinates for the facial landmarks.
    left_eye_w = triangulate(left_eye_pts1, left_eye_pts2, stereoParams);                    
    right_eye_w = triangulate(right_eye_pts1, right_eye_pts2, stereoParams);                    
    nose_tip_w = triangulate(nose_tip_pts1, nose_tips_pts2, stereoParams);                    
                        
    % Find the average point location for each area. Multiple points are selected 
    % to ensure they are tracked from frame to frame.   
    left_eye = median(left_eye_w);
    right_eye = median(right_eye_w);
    nose_tip = median(nose_tip_w);
                    
    z0 = (left_eye(3) + right_eye(3))/2;   % New Z=0 position to be the mean Z of the eyes.
   
    pts_world = triangulate(pts1, pts2, stereoParams);    % Translate to world coordinates.

    % Get a vector in the direction of the new y-axis.
    y_vec = cross(right_eye-left_eye, [0 0 1])); 
    % The new X coordinates will be the dot product with the unit vector
    % pointing along the Y-axis (ignoring Z contribution).
    new_pts(1) = dot([pts_world(:,1:2) zeros(length(pts_world),1)], ...
                              y_vec/norm(y_vec));    
    % The line between the left & right eye defines the X-axis. The
    % distance to this line (ignoring Z coordinates) gives the new Y coordinates.
    new_pts(2) = point_to_line_2D(pts_world, left_eye, right_eye); 
    new_pts(3) = z0 - pts_world(3);   %Z-axis is the same, but the origin is shifted to the eyes.
    
end                                                          
                                
function d = point_to_line_2D(pts, v1, v2)
    % Get perpendicular distance from point to a line.
    % pts should be nx2
    % v1 and v2 are vertices on the line (each 1x2)
    % d is a nx1 vector with the orthogonal distances
    pts(:,3) = zeros(length(pts),1);        % Set the third column to be zero.
    v1(3) = 0; v2(3) = 0;                   % We're interested only in X and Y here.
    v1 = repmat(v1,size(pts,1),1);
    v2 = repmat(v2,size(pts,1),1);
    a = v1 - v2;
    b = pts - v2;
    d = sqrt(sum(cross(a,b,2).^2,2)) ./ sqrt(sum(a.^2,2));
end