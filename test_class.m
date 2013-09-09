clear all;
netObj=HjTcp();

netObj.setHost('172.17.101.1');
netObj.setPort(51027);
%localhost test
netObj.setHost('127.0.0.1'); netObj.setPort(3000);

netObj.connect();
fprintf('connected\n');
%netObj.writeChars(sprintf('++Hello ETG-4000\r\n'));fprintf('sent\n');

fprintf('reading\n');

disp(['single(float): ',num2str(netObj.read('single'))]);
disp(['single(float): ',num2str(netObj.readSingle())]);
disp(['double: ',num2str(netObj.readDouble())]);
disp(['int32: ',num2str(netObj.readInt32())]);
disp(['int8: ',num2str(netObj.readInt8())]);
disp(['int16: ',num2str(netObj.readInt16())]);
fprintf('string specifying num of bytes(UTF8 string): \n%s\n', char(netObj.readString(10)));
fprintf('string (read all data available as string): \n%s\n', char(netObj.readString()));
netObj.close();
