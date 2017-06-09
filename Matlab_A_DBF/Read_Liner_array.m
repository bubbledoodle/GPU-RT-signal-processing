%=============================================================%
% read Array Beam by Carl. Almost the end of whole thesis 
%                      17/Jun/2015
%             @ Harbin Institute of Technology
%=============================================================%

clc; close all; clear all;
BATCH = 2048;
N = 2048;
Beamnum = 31;
Beam_desired = 29;
theta=linspace(-48/180*pi,48/180*pi,Beamnum); %azimuth bin

%% read in statisic and its Formation
% CUDA Processed Data
fid=fopen('CUDA_DBFO1.dat','rb');
%fid= fopen('C:\Users\carly_000\Desktop\DBF_V3\DBF\CUDA_DBF01.dat','rb');
test = fread(fid,N * BATCH * Beamnum,'float32');
test =reshape(test',2,N*BATCH*Beamnum/2);
Beam_real=test(1,:);
Beam_imag=test(2,:);
DBF1=Beam_real+Beam_imag*1j;
DBF1=(reshape(DBF1,2048*BATCH/2,Beamnum)).';

fid=fopen('CUDA_DBFO2.dat','rb');
%fid= fopen('C:\Users\carly_000\Desktop\DBF_V3\DBF\CUDA_DBF02.dat','rb');
test = fread(fid,N*BATCH*Beamnum,'float32');
test =reshape(test',2,N*BATCH*Beamnum/2);
Beam_real=test(1,:);
Beam_imag=test(2,:);
DBF2=Beam_real+Beam_imag*1j;
DBF2=(reshape(DBF2,2048*BATCH/2,Beamnum)).';
CUDA_DBF=[DBF1, DBF2];
clear Beam_real Beam_imag test DBF1 DBF2;

%% find peak
temp=reshape(CUDA_DBF.',2048,2048,Beamnum);
rd=abs(temp(:,:,1));
[fyt,rxt] = find(rd==max((rd(:))));
for n = 1:Beamnum
    patBeam(n) = temp(fyt,rxt,n); 
end

%% ploting 
figure;
plot(theta/pi*180,db(patBeam));
xlabel('Direction of Arrival/degree');
ylabel('Amplitude/dB');
title('DBF Processed by CUDA');
grid on;