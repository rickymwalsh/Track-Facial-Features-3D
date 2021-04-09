function varargout = VideoPlayFigure(varargin)
% VIDEOPLAYFIGURE MATLAB code for VideoPlayFigure.fig
%      VIDEOPLAYFIGURE, by itself, creates a new VIDEOPLAYFIGURE or raises the existing
%      singleton*.
%
%      H = VIDEOPLAYFIGURE returns the handle to a new VIDEOPLAYFIGURE or the handle to
%      the existing singleton*.
%
%      VIDEOPLAYFIGURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIDEOPLAYFIGURE.M with the given input arguments.
%
%      VIDEOPLAYFIGURE('Property','Value',...) creates a new VIDEOPLAYFIGURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VideoPlayFigure_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VideoPlayFigure_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VideoPlayFigure

% Last Modified by GUIDE v2.5 09-Apr-2021 13:27:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VideoPlayFigure_OpeningFcn, ...
                   'gui_OutputFcn',  @VideoPlayFigure_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before VideoPlayFigure is made visible.
function VideoPlayFigure_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VideoPlayFigure (see VARARGIN)

% Choose default command line output for VideoPlayFigure
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VideoPlayFigure wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VideoPlayFigure_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Start_btn.
function Start_btn_Callback(hObject, eventdata, handles)
% hObject    handle to Start_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoObject = handles.videoObject;
axes(handles.axes1);

for frameCount = 2:videoObject.NumberOfFrames
    % Display frames
    %set(handles.text3,'String',num2str(frameCount));
    frame = read(videoObject,frameCount);
    imshow(frame);
    drawnow;
end


% --- Executes on button press in Pause_btn.
function Pause_btn_Callback(hObject, eventdata, handles)
% hObject    handle to Pause_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(get(handles.pushbutton3,'String'),'Pause'))
    set(handles.pushbutton3,'String','Play');
    uiwait();
else
    set(handles.pushbutton3,'String','Pause');
    uiresume();
end


% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[ video_file_name,video_file_path ] = uigetfile({'*.avi'},'Pick a video file');      %;*.png;*.yuv;*.bmp;*.tif'},'Pick a file');
if(video_file_path == 0)
    return;
end
input_video_file = [video_file_path,video_file_name];
% Acquiring video
videoObject = VideoReader(input_video_file);
% Display first frame
frame_1 = read(videoObject,1);
axes(handles.axes1);
imshow(frame_1);
drawnow;
axis(handles.axes1,'off');
%Update handles
handles.videoObject = videoObject;
guidata(hObject,handles);

function setRectangleTrack()
