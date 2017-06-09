%===============================================%
% 线性调频信号示例程序 by carl                       
% 载频（中心频率）3GHz，
% N代表在时间段内有这么多个点，为采样频率乘时间段
% 小t代表时域分割的空间，没有按点来
% V3已经是动目标的回波了
% V4在v3基础上改正了动目标的回波，采样方式，截断方式
%===============================================%
clear all; close all; clc;

%% parameter set
B = 1e6;              %band width @ 200 range bin
D = 10;               %Compression rate 
Tp = 1/B*D;           %pause duration 10us/// resolution depends on Tpreceived = 1/B =====> resolution = 150 meters
tTpp = 2e-3+Tp+1e-6;  %pause repetition time 2ms + little more
K = B/Tp;             %chirp rate
Ns = 2048;            %sampling number 2048
fs = 400e3;           %sampling frenquency
fc = 3e9;             %carrier frenquency
C = 3e8;              %propagation speed
lamda = C/fc;         %wavelength
BATCH = 2048;         %doppler bin 2048
Rmin=0; Rmax=15000;   %range bin
Tr = 2 * Rmax/C + Tp; %sampling bin
R = [110000,100500,70000];% ideal target range
vr = [600, 100, 80];  % targets velocity
snr = 30;

%% phase matrix & signal echo
t = linspace(0,Tr,Ns);%sampling space
tsize = size(t);

target_num = length(R);
phase_trans = 2*pi*fc.*t+pi*K*t.^2;%reference signal
tic;
disp(['Original 3 target distance =',num2str(R)]);
for n=1:1:BATCH
    tau = 2*R/C;
    Aamp = sqrt(10.^(snr/10));
    td = ones(target_num,1)*t-tau'*ones(size(t));
    signal_echo_perbatch = zeros(1,tsize(1,2));
    noise = (1/sqrt(2)*(randn(1,Ns)+1i*randn(1,Ns)));
    for i = 1:1:target_num
        phase_received = 2*pi*(fc).*td+pi*K*td.^2;
        signal_echo_perbatch = signal_echo_perbatch+Aamp*exp(1j*phase_received(i,:)).*(abs(td(i,:))<Tp/2);
    end
    signal_echo(n,:)=signal_echo_perbatch+noise;
    
    if mod(n,128)==0 
        disp(['3 target distance =',num2str(R)]);disp(['batch =', num2str(n)]);
    end
    R=R-vr*tTpp;
end
toc;
signal_trans = exp(1j*phase_trans).*(t<Tp);
Signal_trans = fft(exp(1j*phase_trans));

%% simulated echo statisic forming
Echo_signal=reshape(signal_echo.',1,2048*BATCH);
Echo_real=real(Echo_signal);
Echo_imag=imag(Echo_signal);
Echo_signal=reshape([Echo_real;Echo_imag],1,2048*BATCH*2);
fid= fopen('Echo.dat','wb');
fwrite(fid,Echo_signal,'float32');
fclose(fid);

%% simulated trans statisic forming
Ref_signal=ones(BATCH,1)*signal_trans;
Ref_signal=reshape(Ref_signal.',1,2048*BATCH);
Ref_real=real(Ref_signal);
Ref_imag=imag(Ref_signal);
Ref_signal=reshape([Ref_real;Ref_imag],1,2048*BATCH*2);
fid= fopen('ReferenceTrans.dat','wb');
fwrite(fid,Ref_signal,'float32');
fclose(fid);