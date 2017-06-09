%==========================================================================%
% This code is to demostrate pause compression based on Matlab. For testing
% the speed and accuracy of CUDA parallel algorithm. 
%
% ##In file list:    PauseCompression.dat    @ echo
%                    ReferenceTrans.dat      @ reference
% ##Out file list:   T_Pause_compression.dat @ PC Processed by Matlab
%                    F_Doppler.dat           @ Doppler Processed by Matlab
%
% By carl @ 27/May/2015
% @Harbin Institute of Technology
%==========================================================================%
clear all; close all; clc;

%% parameteres
N = 2048;
B = 1e5;
D=10;
Tp = 1/B*D; 
Tr = 2e-3+Tp+1e-6;
BATCH = 2048;
fs = N/Tr;
t = linspace(0,Tr,N);
C=3e8;
%% read in statisic
fid = fopen('Echo.dat','rb');
signal_echo=fread(fid,2048*BATCH*2,'float32');
fclose(fid);
fid = fopen('ReferenceTrans.dat','rb');
signal_trans=fread(fid,2048*2,'float32');
fclose(fid);

signal_trans=reshape(signal_trans,2,2048);
signal_trans=[signal_trans(1,:)+1j*signal_trans(2,:)];
Signal_trans=fft(signal_trans(1,:));

signal_echo=reshape(signal_echo',2,2048*BATCH);
signal_echo=[signal_echo(1,:)+1j*signal_echo(2,:)];
signal_echo=(reshape(signal_echo,2048,BATCH)).';

% signal_trans in col; signal_echo in row
Signal_trans=(repmat(Signal_trans,2048,1)).';
signal_echo=signal_echo.';
%% Pause compression
disp('Starting pause commpression processing');
tic;
Signal_echo_Freq = fft(signal_echo);
F_Pause_compression = Signal_echo_Freq.*conj(Signal_trans);
T_Pause_compression = (ifft(F_Pause_compression));
toc;
disp('Finished Pause Compression');
T_Pause_compression = T_Pause_compression.';

%% Doppler
disp('Starting doppler processing');
signal_doppler=T_Pause_compression;
tic;
F_Signal_doppler=fft(signal_doppler);
%F_Signal_doppler=F_Signal_doppler;
toc;
disp('Finished Doppler Processing');
%% plot
% figure;
n = 1:1:BATCH;
% mesh(t*1e3,n,abs(signal_echo));axis tight;
% title('Range-Doppler plot of unpressed data');
disp('Sample figures (figure 1 to 3) to check signal processed by Matlab');

figure;
subplot(211);plot(t*1e6,abs(real(signal_echo(:,1))));grid on;
title('Time-Magnitude spectrum of chirp signal');
xlabel('Time in u sec');ylabel('Amplitude');

subplot(212);plot(t*C/2/1000,abs(Signal_echo_Freq(1,:)));title('Frequency-Magnitude spectrum of chirp signal');
xlabel(['simpling frenquence is',num2str(fs/B),' times to bandwidth']);grid on;

figure;
plot(t*C/2/1000,abs(T_Pause_compression(1,:)));grid on;
title('Time-Magnitude spectrum of Pause Compression signal');
xlabel('Target distance in kilometers');ylabel('Amplitude');

figure;
%surf(300/2048*n,n,abs(F_Signal_doppler));grid on;axis tight;
Max=max(max(abs(F_Signal_doppler)));
Min=min(min(abs(F_Signal_doppler)));
s6=round(255*(abs(F_Signal_doppler)-Min)/(Max-Min));
colormap(gray)
image(300/2048*n,n,s6);
xlabel('Target range in kilometers');
ylabel('Batch');
title('Range-Doppler Processed Data');

%% write out
T_Pause_compression=reshape(T_Pause_compression.',1,2048*BATCH);
PC_real=real(T_Pause_compression);
PC_imag=imag(T_Pause_compression);
T_Pause_compression=reshape([PC_real;PC_imag],1,2048*BATCH*2);
fid = fopen('T_Pause_compression.dat','wb');
fwrite(fid,T_Pause_compression,'float32');
fclose(fid);

F_Doppler=reshape(F_Signal_doppler.',1,2048*BATCH);
D_real=real(F_Doppler);
D_imag=imag(F_Doppler);
F_Doppler=reshape([D_real;D_imag],1,2048*BATCH*2);
fid = fopen('F_Doppler.dat','wb');
fwrite(fid,F_Doppler,'float32');
fclose(fid);