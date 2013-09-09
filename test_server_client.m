clear all;

%execute server on a machine and the client on another (or another matlab)
server=HjTcp('server');
server.setPort(3000);
server.connect('-v');

client=HjTcp();
client.setHost('127.0.0.1');
client.setPort(3000);

client.connect('-v');
fprintf('connected\n');
%client.writeChars(sprintf('++Hello ETG-4000\r\n'));fprintf('sent\n');

fprintf('reading and writing\n');
%{
disp(['single(float): ',num2str(client.read('single'))]);
disp(['single(float): ',num2str(client.readSingle())]);
disp(['double: ',num2str(client.readDouble())]);
disp(['int32: ',num2str(client.readInt32())]);
disp(['int8: ',num2str(client.readInt8())]);
disp(['int16: ',num2str(client.readInt16())]);
fprintf('string specifying num of bytes(UTF8 string): \n%s\n', char(client.readString(10)));
fprintf('string (read all data available as string): \n%s\n', char(client.readString()));

%}
client.close();
server.close();