%==================================================================%
%This code is build to help understand array signal and digtial beam
%forming. collected via internet and modified by Carl in 18/May/2015
%Version 3 modified in 17/Jun/2015
%==================================================================%

clc; clear all; close all;  
BATCH = 2048;
N = 2048;
B = 1e5;             %band width @ 200 range bin/ resolution 1.5km
D=10;
Tp = 1/B*D;            %pause duration 10us
Tr = 2e-3+Tp+1e-6;   %pause repetition time 2ms + little more
C=3e8;
%% Data read in
% set as channel one signal
tic;
fid = fopen('F_Doppler.dat','rb');
signal_echo=fread(fid,2048*BATCH*2,'float32');
fclose(fid);
signal_echo=reshape(signal_echo',2,2048*BATCH);
signal_echo=[signal_echo(1,:)+1j*signal_echo(2,:)];
disp('Finished read in echo signal');

%==============test find peak point in RD==========%
rd = abs(signal_echo);
[fyt,rxt] = find(rd==max((rd(:))));
rangeee=signal_echo(rxt);
%==================================================%

toc;
%% Parameters & initializing
element_num = 32;
azimuth_num = 31;
Lamda=0.1;
d=0.05;
dLamdaR=0.25;
theta_in=5/180*pi; 
p=zeros(200,1);

%% Phase difference implementing
theta=linspace(-48/180*pi,48/180*pi,azimuth_num); %azimuth bin
a=exp(1j*2*pi*dLamdaR*sin(theta_in)*[0:element_num-1]'); % weight bin
for n=1:azimuth_num
    w(:,n)=exp(1j*2*pi*dLamdaR*sin(theta(n))*[0:element_num-1]'); %phase difference matrix
end
channel=a*signal_echo;
% %=================================================================================%
% Array01=channel(:,1:2097152);
% Array02=channel(:,2097153:4194304);
% 
%%write array signal
% Array_signal=reshape(Array01.',1,2048*BATCH*element_num/2);
% Array_real=real(Array_signal);
% Array_imag=imag(Array_signal);
% Array_signal=reshape([Array_real;Array_imag],1,2048*BATCH*2*element_num/2);
% fid= fopen('Array1.dat','wb');
% fwrite(fid,Array_signal,'float32');
% fclose(fid);
% 
% Array_signal=reshape(Array02.',1,2048*BATCH*element_num/2);
% Array_real=real(Array_signal);
% Array_imag=imag(Array_signal);
% Array_signal=reshape([Array_real;Array_imag],1,2048*BATCH*2*element_num/2);
% fid= fopen('Array2.dat','wb');
% fwrite(fid,Array_signal,'float32');
% fclose(fid);
% 
% clear varables not necessaty any more!!
% clear Array01; clear Array02; clear Array_signal; clear Array_real; clear Array_imag;
% disp('Finished array signal forming & cleared some Memo');
% disp('=========================================================================');
% %==================================================================================%
%% DBF
tic;
disp('Starting DBF');
temp=channel.'*conj(w);
toc;
disp('End of DBF');

% save some f**e data [^.^]
channel01=temp(1:2097152,:);
Array_signal=reshape(channel01,1,2048*BATCH*31/2);
Array_real=real(Array_signal);
Array_imag=imag(Array_signal);
Array_signal=reshape([Array_real;Array_imag],1,2048*BATCH*2*31/2);
fid= fopen('CUDA_DBFO1.dat','wb');
fwrite(fid,Array_signal,'float32');
fclose(fid);
channel01=temp(2097153:4194304,:);
Array_signal=reshape(channel01,1,2048*BATCH*31/2);
Array_real=real(Array_signal);
Array_imag=imag(Array_signal);
Array_signal=reshape([Array_real;Array_imag],1,2048*BATCH*2*31/2);
fid= fopen('CUDA_DBFO2.dat','wb');
fwrite(fid,Array_signal,'float32');
fclose(fid);
clear Array_signal; clear Array_real; clear Array_imag; clear channel01;

temp=reshape(temp,2048,2048,azimuth_num);
rd=abs(temp(:,:,1));
[fyt,rxt] = find(rd==max((rd(:))));
for n = 1:azimuth_num
    patBeam(n) = temp(fyt,rxt,n); 
end


%% Ploting
figure;
subplot(121);
plot(theta/pi*180,db(patBeam));
% xlabel('Direction of Arrival/degree');
% ylabel('Amplitude/dB');
% title('DBF Processed by Matlab');
xlabel('角度/°');
ylabel('幅度/dB');
title('Matlab运行得到的DBF结果');
grid on;

subplot(122);
plot(theta/pi*180,db(patBeam));
% xlabel('Direction of Arrival/degree');
% ylabel('Amplitude/dB');
% title('DBF Processed by CUDA');
xlabel('角度/°');
ylabel('幅度/dB');
title('CUDA运行得到的DBF结果');
grid on;

figure;
    signal_test=(reshape(temp(:,:,1),2048,BATCH)).';
    mesh(db(signal_test));view(2);axis tight;