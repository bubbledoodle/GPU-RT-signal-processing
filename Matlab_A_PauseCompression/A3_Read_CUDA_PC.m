%======================================================%
% Read & test outcome by carl @27/May/2015
%
% ##In file list: 1.CUDA_PauseCompression.dat
%                 2.CUDA_Doppler.dat
%                 3.F_Doppler.dat
%                 4.T_Pause_Compression.dat
%
%======================================================%
clc; close all; clear all;
BATCH =2048;
BATCH_Desire=1960;

%% statisic read in and formation
% Processed by CUDA
fid= fopen('CUDA_PauseCompression.dat','rb');
test = fread(fid,2048*BATCH*2,'float32');
test = test/2048; % one of CUDA's problem that gives back a non-normolization IFFT consequence
test =reshape(test',2,2048*BATCH);
T_CUDA_PC_real=test(1,:);
T_CUDA_PC_imag=test(2,:);
T_CUDA_Pause_Compression=T_CUDA_PC_real+T_CUDA_PC_imag*1j;
T_CUDA_Pause_Compression=(reshape(T_CUDA_Pause_Compression,2048,BATCH)).';
disp('Finished read in pause compression DATA processed by CUDA');

fid= fopen('CUDA_RD.dat','rb');
test = fread(fid,2048*BATCH*2,'float32');
test = test/2048; % one of CUDA's problem that gives back a non-normolization IFFT consequence
test =reshape(test',2,2048*BATCH);
F_CUDA_RD_real=test(1,:);
F_CUDA_RD_imag=test(2,:);
F_CUDA_Doppler=F_CUDA_RD_real+T_CUDA_PC_imag*1j;
F_CUDA_Doppler=reshape(F_CUDA_Doppler,2048,BATCH);
disp('Finished read in Doppler DATA processed by CUDA');

% Processed by Matlab
fid= fopen('F_Doppler.dat','rb');
F_D = fread(fid,2048*BATCH*2,'float32');
F_D =reshape(F_D',2,2048*BATCH);
F_D_real=F_D(1,:);
F_D_imag=F_D(2,:);
F_Doppler=F_D_real+F_D_imag*1j;
F_Doppler=(reshape(F_Doppler,2048,BATCH)).';
disp('Finished read in doppler DATA processed by Matlab');

fid= fopen('T_Pause_Compression.dat','rb');
T_PC = fread(fid,2048*BATCH*2,'float32');
T_PC =reshape(T_PC',2,2048*BATCH);
T_PC_real=T_PC(1,:);
T_PC_imag=T_PC(2,:);
T_Pause_Compression=T_PC_real+T_PC_imag*1j;
T_Pause_Compression=(reshape(T_Pause_Compression,2048,BATCH)).';
disp('Finished read in pause compression DATA processed by Matlab');

%% Plot
% BATCH =1;
disp('Figure 1 to 2 compared pause compression data');
disp('Figure 3 compared doppler data');

%=========Batch1=========
figure;
subplot(211);
n=1:1:2048;
plot(300/2048*n,abs(T_CUDA_Pause_Compression(1,:)));axis tight;
%title('Processed by CUDA, BATCH = 1');grid on;
%xlabel('Target distance in Kilometers');ylabel('Amplitude');
%=======I turely don't want to wirte code in Chinese=========%
%=======But I was forced to change, WTF======================%
title('CUDA 计算结果, 批次 = 1');grid on;
xlabel('目标距离/Km');ylabel('幅度');
set(gca,'FontName','Times New Roman','FontSize',10.5);
subplot(212);
plot(300/2048*n,abs(T_Pause_Compression(1,:)));
% title('Processed by Matlab, BATCH = 1');axis tight;grid on;
% xlabel('Target distance in Kilometers');ylabel('Amplitude');
%=============================================================================
title('Matlab 计算结果, 批次 = 1');grid on;
xlabel('目标距离/Km');ylabel('幅度');
set(gca,'FontName','Times New Roman','FontSize',10.5);
% BATCH = 3000;

%======BatchN=========
figure; 
subplot(211);
plot(300/2048*n,abs(T_CUDA_Pause_Compression(BATCH_Desire,:)));axis tight;
% title(['Processed by CUDA, BATCH = ',num2str(BATCH_Desire)]);grid on;
% xlabel('Target distance in Kilometers');ylabel('Amplitude');
%=============================================================================
title(['CUDA 计算结果, 批次 = ',num2str(BATCH_Desire)]);grid on;
xlabel('目标距离/Km');ylabel('幅度');
set(gca,'FontName','Times New Roman','FontSize',10.5);
subplot(212);
plot(300/2048*n,abs(T_Pause_Compression(BATCH_Desire,:)));
% xlabel('Target distance in Kilometers');ylabel('Amplitude');
% title(['Processed by Matlab, Batch = ',num2str(BATCH_Desire)]);axis tight;grid on;
%=============================================================================
title(['Matlab 计算结果, 批次 = ',num2str(BATCH_Desire)]);grid on;
xlabel('目标距离/Km');ylabel('幅度');
set(gca,'FontName','Times New Roman','FontSize',10.5);

%======R-D-gray=========
n=1:1:2048;
figure;
subplot(121);
Max=max(max(abs(F_Doppler)));
Min=min(min(abs(F_Doppler)));
s6=round(255*(abs(F_Doppler)-Min)/(Max-Min));
colormap(gray)
image(300/2048*n,n,s6);grid on;axis tight; %axis([300 850 1 500]);
% xlabel('Target range in kilometers'); ylabel('Batch');
% title('R-D Data Processed by Matlab');
xlabel('目标距离/Km'); ylabel('批次');
title('由Matlab程序运行产生的R-D图');
set(gca,'FontName','Times New Roman','FontSize',10.5);


subplot(122);
Max=max(max(abs(F_CUDA_Doppler)));
Min=min(min(abs(F_CUDA_Doppler)));
s6=round(255*(abs(F_CUDA_Doppler)-Min)/(Max-Min));
colormap(gray)
image(300/2048*n,n,s6); grid on;axis tight; %axis([300 850 1 500]);
% xlabel('Target range in kilometers'); ylabel('Batch');
% title('R-D Data Processed by CUDA');
xlabel('目标距离/Km'); ylabel('批次');
title('由CUDA程序运行产生的R-D图');
set(gca,'FontName','Times New Roman','FontSize',10.5);

%======R-D-mesh========
figure;
subplot(121);
mesh(db(F_CUDA_Doppler));view(2);axis tight
title('由CUDA计算得到的R-D图');
xlabel('距离/Km');ylabel('批次');
set(gca,'FontName','Times New Roman','FontSize',10.5);

subplot(122);
mesh(db(F_Doppler));view(2);axis tight
title('由Matlab计算得到的R-D图');
xlabel('距离/Km');ylabel('批次');
set(gca,'FontName','Times New Roman','FontSize',10.5);
