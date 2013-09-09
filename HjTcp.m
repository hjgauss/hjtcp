% HjTcp
% a wrapper for a java tcpip client for matlab
%
% author: Enrico Opri
% First versione uploaded on 09/09/2013
%
classdef HjTcp < handle 

    properties(GetAccess = 'public', SetAccess = 'private')
      	port;
     	host;
    	timeout=60000;% 1 min
        DEFAULT_READ_BUFFER=2048;
        FORCE_FLUSH_AFTER_WRITE=0;
        NETWORK_ROLE=0;%0 is client, 1 is server
        isSwapBytes=1;
    end
    properties(GetAccess = 'private', SetAccess = 'private')
    	socket;
        outStream;
        inStream;
        
    end
    methods
        function self = HjTcp(varargin)
            %default is to define a client connection
            if nargin>0
                network_role=varargin{1};
                if strcmp(network_role, 'server')
                    self.NETWORK_ROLE=1;
                elseif strcmp(network_role, 'client')
                    self.NETWORK_ROLE=0;
                else
                    error('hjtcp:malformedInit','the specified network role is not valid. Use the keyword ''client'' or ''server''.');
                end
            end
        end
        %//////// SETTERS //////////
        function setPort(self, port_num)
            if port_num < 1025 || port_num > 65535 || ceil(port_num) ~= floor(port_num)
                %avoid to use ports lower than 1024 (reserved ports)
                %usually win xp use ports between 1024 and 5000
                error('port number not valid. It must be an integer value between 1025 and 65535.');
            end
            self.port=port_num;
        end
        
        function setHost(self, str_address)
            if ~ischar(str_address)
                error('host address must be specified as string');
            end
            self.host=str_address;
        end
        
        function setTimeout(self, value)
            %set timeout value in milliseconds
            if value < 1 || ceil(value) ~= floor(value) 
                error('timeout must be an integer positive number (timeout in milliseconds)');
            end
            self.timeout=value;
        end

        function setIsSwapbytes(self, value)
            switch (value)
                case 'true'
                    self.isSwapBytes=1;
                case 'false'
                    self.isSwapBytes=0;
                otherwise
                    error('specify or true or false');
            end
        end

        function setDefaultReadBuffer(self, value)
            %set buffer value in bytes
            self.DEFAULT_READ_BUFFER=value;
        end

        function setAsServer(self)
            self.NETWORK_ROLE=1;
        end

        function setAsClient(self)
            self.NETWORK_ROLE=0;
        end
        %///////// METHODS /////////
        
        %-- CONNECTION MANAGEMENT --
        function connect(self, varargin)
            if sum(strcmp(varargin,'-v'))>0
                verbose_flag=1;
            else
                verbose_flag=0;
            end

            if self.NETWORK_ROLE==0
                %create socket
                self.socket = java.net.Socket();
                self.socket.setSoTimeout(self.timeout);
                sckAddr = java.net.InetSocketAddress(self.host,self.port); 
                %connect
                try 
                    self.socket.connect(sckAddr,self.timeout); 
                    self.socket.setSoTimeout(self.timeout);
                catch ex
                    error('hjtcp:connClientFailed','Failed to Initialize conn.\nJava Trace:\n%s',ex.message);
                end

                if verbose_flag
                    fprintf('client connected to server\n');
                end
            else
                if self.host~=[]
                    warning('hjtcp:argHostNotRequired','host address will be ignored, only the port number is used');
                end
                sckServer = java.net.ServerSocket(self.port);
                %connect
                if verbose_flag
                    fprintf('waiting for connection\n');
                end
                try 
                    self.socket=sckServer.accept(); 
                    self.socket.setSoTimeout(self.timeout);
                catch ex
                    error('hjtcp:connServerFailed','Failed to Initialize conn.\nJava Trace:\n%s',ex.message);
                end

                if verbose_flag
                    fprintf('server connected to a client\n');
                end
            end

            self.outStream = java.io.DataOutputStream(self.socket.getOutputStream());
            self.inStream = self.socket.getInputStream();

            %self.inStream = java.io.DataInputStream(java.io.BufferedInputStream(self.socket.getInputStream(),1024));
        end
        
        function close(self)
            self.outStream.close();
            self.inStream.close();
            self.socket.close();
        end

        function flush(self)
            self.outStream.flush();
        end
        
        function num_out = numBytesAvailable(self)
            num_out=self.inStream.available;
        end
        
        %------- READ METHODS ------
        
        function response = read(self, varargin)
        % obj.read(self[, type, numBytesToRead])
        %returns java string not array of matlab char (conversion is slow and less useful)
            response=[];
            response_type='string';
            num_bytes_to_read=0;%0 is infinite

            if nargin>1
                response_type=varargin{1};
                disp(response_type);
            end
            if nargin>2
                num_bytes_to_read=varargin{2};
            end

            if strcmp(response_type, 'string')
                inputChannel = java.nio.channels.Channels.newChannel(self.inStream);

                charset = java.nio.charset.Charset.forName('US-ASCII');
                decoder = charset.newDecoder;
                inputLine = java.lang.StringBuffer;

                if num_bytes_to_read == 0
                    while 1
                        buf = java.nio.ByteBuffer.allocate(self.DEFAULT_READ_BUFFER);
                        inputChannel.read(buf);
                        buf.flip();
                        inputLine.append(decoder.decode(buf));

                        if self.inStream.available==0
                            break;
                        end
                    end
                
                else
                    buf = java.nio.ByteBuffer.allocate(num_bytes_to_read);
                    bytesRead = inputChannel.read(buf);
                    buf.flip();
                    inputLine.append(decoder.decode(buf));
                end
                
                response=inputLine.toString();
            elseif strcmp(response_type, 'int8')
                in=java.io.DataInputStream(self.inStream);
                response=int8(in.readByte());
            elseif strcmp(response_type, 'int16')
                in=java.io.DataInputStream(self.inStream);
                response=int16(in.readShort());
            elseif strcmp(response_type, 'int32')
                in=java.io.DataInputStream(self.inStream);
                response=int32(in.readInt());
            elseif strcmp(response_type, 'int64')
                in=java.io.DataInputStream(self.inStream);
                response=int64(in.readLong());
            elseif strcmp(response_type, 'single')
                in=java.io.DataInputStream(self.inStream);
                response=single(in.readFloat());
            elseif strcmp(response_type, 'double')
                in=java.io.DataInputStream(self.inStream);
                response=double(in.readDouble());
            end

        end
        
        % SINGLE DATATYPE READ METHODS
        function response = readInt8(self)
            in=java.io.DataInputStream(self.inStream);
            
            response=int8(in.readByte());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readInt16(self)
            in=java.io.DataInputStream(self.inStream);
            response=int16(in.readShort());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readInt32(self)
            in=java.io.DataInputStream(self.inStream);
            response=int32(in.readInt());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readInt64(self)
            in=java.io.DataInputStream(self.inStream);
            response=int64(in.readLong());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readSingle(self)
            in=java.io.DataInputStream(self.inStream);
            response=single(in.readFloat());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readDouble(self)
            in=java.io.DataInputStream(self.inStream);
            response=double(in.readDouble());
            if self.isSwapBytes
                response=swapbytes(response);
            end
        end
        
        function response = readString(self, varargin)
            num_bytes_to_read=0;%0 is infinite

            if nargin>1
                num_bytes_to_read=varargin{1};
            end
            
            inputChannel = java.nio.channels.Channels.newChannel(self.inStream);

            charset = java.nio.charset.Charset.forName('US-ASCII');
            decoder = charset.newDecoder;
            inputLine = java.lang.StringBuffer;

            if num_bytes_to_read == 0
                while 1
                    buf = java.nio.ByteBuffer.allocate(self.DEFAULT_READ_BUFFER);
                    inputChannel.read(buf);
                    buf.flip();
                    inputLine.append(decoder.decode(buf));

                    if self.inStream.available==0
                        break;
                    end
                end

            else
                buf = java.nio.ByteBuffer.allocate(num_bytes_to_read);
                bytesRead = inputChannel.read(buf);
                buf.flip();
                inputLine.append(decoder.decode(buf));
            end

            response=inputLine.toString();
        end

        function response=readChars(self)
            %do not use this method if you want speed. 
            %The conversion from java String to matlab char datatype is slow.
            num_bytes_to_read=0;%0 is infinite

            if nargin>1
                num_bytes_to_read=varargin{1};
            end
            response=char(self.readString(num_bytes_to_read));
        end

        %------ WRITE METHODS ------
        
        function writeInt8(self)
            self.writeBytes();
        end
        
        function writeBytes(self, data)
            if ~isa(data,'int8')
                error('wrong datatype, it must be ''int8''.');
            end
            self.outStream.write(data,0,length(data));

            if self.FORCE_FLUSH_AFTER_WRITE==1
                self.outStream.flush();
            end
        end
        
        function writeChars(self, data)
            if ~ischar(data)
                error('wrong datatype, it must be ''char''.');
            end
            %write UTF8
            self.outStream.writeBytes(java.lang.String(data));

            if self.FORCE_FLUSH_AFTER_WRITE==1
                self.outStream.flush();
            end
        end
        
        function writeCharsUTF16(self, data)
            if ~ischar(data)
                error('wrong datatype, it must be ''char''.');
            end
            %write UTF16
            self.outStream.writeChars(java.lang.String(data));

            if self.FORCE_FLUSH_AFTER_WRITE==1
                self.outStream.flush();
            end
        end
        
        function writeString(self, data)
            %write UTF8
            self.outStream.writeBytes(data);

            if self.FORCE_FLUSH_AFTER_WRITE==1
                self.outStream.flush();
            end
        end
        
    end
    
end