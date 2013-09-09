% Script RealtimeOT
% Realtime LAN function for OTsystem using MATLAB
% 
% coded by Enrico Opri
% based on the script of S.Kawasaki "reatimeOT.m"
%
%need to send 
%first command for connection (after wait for ok response)
% '++Hello ETG-4000\r\n'
% second connect and wait for data
% header		:   4 byte DWORD (generally 12 byte)
% data number	:   4 byte LONG
% data size		:   4 byte DWORD (generally 428 hbdata+mark+time)
% hb data		: 416 byte FLOAT
% mark 			:   2 byte SHORT
% time			:  10 byte CHAR
% total byte sent 440
% lets set out buffer to 512

%vars
plot_ch=48;%Ex: Probe1(4x4Mode 24ch)=1-24ch, Probe2(4x4Mode 24ch)=25-48ch
n_channels = 52;

%/********* DATA STRUCTURE *********/
%columns = channels
%rows = single acquisition
buffer_data_etg_len = 1024;
buffer_data_etg = zeros(buffer_data_etg_len,n_channels*2);

%prep conn
netObj=HjTcp();
netObj.setHost('172.17.101.1');%set ip of the machine (ETG-4000), need to set the client ip (the executor of this script) on the same network ex.172.17.101.2
netObj.setPort(51027);

%/************* FIGURE *************/
%{
figureHandle = figure('NumberTitle','off',...
    'Name','Live Data Stream Plot',...
    'CloseRequestFcn',{@closeView, netObj});
    %'Color',[0 0 0],...
%}
%axesHandle = axes('YGrid','on',...
    %'XGrid','on');
    %'Parent',figureHandle,...
    %'YColor',[0.9725 0.9725 0.9725],...
    %'XColor',[0.9725 0.9725 0.9725],...
    %'Color',[0 0 0],...
figure
hold on;
box on;
grid on;

%xlabel(axesHandle,'Number of Samples');
%ylabel(axesHandle,'Value');

set(1,'doublebuffer','on');
set(gca,'drawmode','fast');
title(['Probe1 CH',num2str(plot_ch)]);
%fh1=plot(axesHandle,0,0,'r','LineWidth',1);
fh1=plot(0,0,'r','LineWidth',1);
fh2=plot(0,0,'g','LineWidth',1);
drawnow;

%/************* CONN *************/
snapnow;
pause(3);
%open connection
netObj.connect();
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
%and send hello command
netObj.writeChars(sprintf('++Hello ETG-4000\r\n'));
fprintf('hello Machine');

%Receive Command from ETG-4000
fprintf('echo : %s',char(netObj.read()));
disp('press START Button to start acquisition');

%input('press button');
%disp('starting listening');
i=0;
while(1)
    try
        i=i+1;
        fprintf('read #%g',i);
        %# shift data by one row
        buffer_data_etg(2:end,:)=buffer_data_etg(1:end-1,:);

        %# read header
        h_size = netObj.readInt32();%unsigned int
        
        %if h_size==12
            dt_num = netObj.readInt32();%unsigned int
            dt_size = netObj.readInt32();%unsigned int
            
            %# read data
            for ch=1:n_channels;%Oxy
                buffer_data_etg(1,ch)=netObj.readSingle();
            end;
            for ch=n_channels+1:n_channels*2;%DeOxy
                buffer_data_etg(1,ch)=netObj.readSingle();
            end;

            %# read Mark
            mark=netObj.readInt16();

            %# read Time
            num_str_bytes=netObj.numBytesAvailable();
            timeString=netObj.readString(10);
    
            %# show data
            %if dt_num>=1;%Plot Oxy&Deoxy
                set(fh1,'xdata',[1:buffer_data_etg_len],'ydata',buffer_data_etg(1:buffer_data_etg_len,plot_ch));%set(h1,'color','r');
                set(fh2,'xdata',[1:buffer_data_etg_len],'ydata',buffer_data_etg(1:buffer_data_etg_len,plot_ch+52));%set(h2,'color','b');
                drawnow;
            %end;
        %end;
    catch ME
        %connection error, closing socket
        netObj.close();
        fprintf('connection lost\n');
        break;
    end
end