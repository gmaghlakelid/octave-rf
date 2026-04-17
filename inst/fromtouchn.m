function [freq,data,npts] = fromtouchn(filename)

%FROMTOUCHN.
%   [freq,data,npts] = fromtouchn(filename) returns matlab variables from
%   a data file in touchstone format (.snp file)
%
%   NPTS is the total number of the frequency samples.
%   FREQ is a vector containing the frequency axes;
%   DATA is a n by n by npts 3D matrix that has for each frequency
%       the S parameter n by n matrix.
%   Where filename is a string containing the whole pathname of the snp file:
%   Example for 4 port parameter: 
%       FILENAME = 'C:\Documents and Settings\My S Parameters\myS.s4p'.
%
%   A global variable MIXEDMODECHECK is set to 1 when the s4p data are already in
%   mixed-mode format, 0 otherwise (standard format).
%
%   To manage the directory where S-parameters lie, use PWD and CD
%   functions.
%
%   See also IN2TOUCHN, PWD, CD.

% This program load whatever S parameter from s1p to s99p. Developed by
% Francesco de Paulis on November 2006. UMR-EMC Lab, Rolla.

global mixedmodecheck
mixedmodecheck = 0;
mixed_normal = 1;

point_s = findstr(lower(filename),'.s');

point_p = findstr(lower(filename(point_s(end):length(filename))),'p');

%Find the correct kind (n) of the SnP parameter
    if point_p == 4 %For 1-digit n parameter (n=1:9)
        char_n = filename(point_s(end) +2);
    elseif point_p == 5 %For 2-digit n parameter (n=10:99)
        char_n = filename(point_s(end) +2 : point_s +3);
    end

    n = str2num(char_n);

    
%Open the file and start to read the initial 
    fid   = fopen(filename);
    line  = fgetl(fid); 
    
    while isempty(line)
        line = fgetl(fid);
    end 
    
    while (line(1) == '!') | (line(1) =='#'),
        if (line(1) == '#')
            if(strfind(upper(line),'HZ'))
                freqin = 1;
            end
            if(strfind(upper(line),'KHZ'))
                freqin = 1e3;
            end
            if(strfind(upper(line),'MHZ'))
                freqin = 1e6;
            end
            if(strfind(upper(line),'GHZ'))
                freqin = 1e9;
            end
            if(strfind(upper(line),'DB'))
                dataform = 1;
            end
            if(strfind(upper(line),'MA'))
                dataform = 2;
            end
            if(strfind(upper(line),'RI'))
                dataform = 3;
            end
            if(strfind(upper(line),' S '))
                datatype = 1;
            end
            if(strfind(upper(line),' Z '))
                datatype = 2;
            end
            if(strfind(upper(line),' Y '))
                datatype = 3;
            end
            if(strfind(upper(line),' H '))
                datatype = 4;
            end

            % find the reference impedance
            charR = findstr(upper(line),'R');
            if length(charR) == 2 % if the data format is in RI, findstr produces two numbers
                if strcmp(line(charR(1) + 1), 'I') % if the character after R in the first entry is I, use the second entry
                    charR = charR(2);
                else % if the second character in the first entry is not I, use the first entry
                    charR = charR(1);
                end
            end

            Refimpstr = line(charR+1:length(line));
            Refimp = str2num(Refimpstr);
        
    % Check whether the S-parameter data are already in mixed-mode 
        elseif (line(1) == '!') % Find a string containing one of the 16 mixed-mode parameters
            if isempty(findstr(lower(line),'s13 = sdc11')) == 0; % This is for the normal format:
                % |Sdd11 Sdd12 Sdc11 Sdc12|
                % |Sdd21 Sdd22 Sdc21 Sdc22|
                % |Scd11 Scd12 Scc11 Scc12|
                % |Scd21 Scd22 Scc21 Scc22|
                mixedmodecheck = 1;
                mixed_normal = 1;
                
            elseif isempty(findstr(lower(line),'s13 = sdd21')) == 0; % This is for the different file format:
                % |Sdd11 Sdd12 Sdd21 Sdd22|
                % |Sdc11 Sdc12 Sdc21 Sdc22|
                % |Scd11 Scd12 Scd21 Scd22|
                % |Scc11 Scc12 Scc21 Scc22|
                mixedmodecheck = 1;
                mixed_normal = 0;
                
            end
        end
        line = fgetl(fid);
        
        while isempty(line)
            line = fgetl(fid);
        end
        
    end
    
    
%Load s1p parameter
    if n == 1
        nf = 1;
        while line ~= -1,
            v            =  sscanf(line,'%f');
            if (length(v) == 3)
                freq(1,nf)     = v(1);
                if (dataform == 1)
                    data(1,1,nf) = 10^(v(2)/20)*exp(j*v(3)/180*pi);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
                if (dataform == 2)
                    data(1,1,nf) = v(2)*exp(j*v(3)/180*pi);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
                if (dataform == 3)
                    data(1,1,nf) = v(2)+j*v(3);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
            else
                line = fgetl(fid);
            end
            if isempty(line)
                line = fgetl(fid);
            end
        end
        freq = freq*freqin;
        npts = nf-1;

%Load s2p parameter
    elseif n == 2      
        nf = 1;
        while line ~= -1,
            v            =  sscanf(line,'%f');
            if (length(v) == 9)
                freq(1,nf)     = v(1);
                if (dataform == 1)
                    data(1,1,nf) = 10^(v(2)/20)*exp(j*v(3)/180*pi);
                    data(2,1,nf) = 10^(v(4)/20)*exp(j*v(5)/180*pi);
                    data(1,2,nf) = 10^(v(6)/20)*exp(j*v(7)/180*pi);
                    data(2,2,nf) = 10^(v(8)/20)*exp(j*v(9)/180*pi);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
                if (dataform == 2)
                    data(1,1,nf) = v(2)*exp(j*v(3)/180*pi);
                    data(2,1,nf) = v(4)*exp(j*v(5)/180*pi);
                    data(1,2,nf) = v(6)*exp(j*v(7)/180*pi);
                    data(2,2,nf) = v(8)*exp(j*v(9)/180*pi);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
                if (dataform == 3)
                    data(1,1,nf) = v(2)+j*v(3);
                    data(2,1,nf) = v(4)+j*v(5);
                    data(1,2,nf) = v(6)+j*v(7);
                    data(2,2,nf) = v(8)+j*v(9);
                    nf = nf + 1;
                    line = fgetl(fid);
                end
            else
                line = fgetl(fid);
            end
            if isempty(line)
                line = fgetl(fid);
            end
        end
        freq = freq*freqin;
        npts = nf-1;
        
%Load s3p parameter (s3p has only 3 elements per line and three line per each frequency)
    elseif n == 3
        nf = 1;
        while ((line ~= -1)),
            v            =  sscanf(line,'%f');
            lenv = length(v);
            if (lenv == 7)
                freq(1,nf)     = v(1);
                if (dataform == 1)
                    data(1,1,nf) = 10^(v(2)/20)*exp(j*v(3)/180*pi);
                    data(1,2,nf) = 10^(v(4)/20)*exp(j*v(5)/180*pi);
                    data(1,3,nf) = 10^(v(6)/20)*exp(j*v(7)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = 10^(v(1)/20)*exp(j*v(2)/180*pi);
                    data(2,2,nf) = 10^(v(3)/20)*exp(j*v(4)/180*pi);
                    data(2,3,nf) = 10^(v(5)/20)*exp(j*v(6)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = 10^(v(1)/20)*exp(j*v(2)/180*pi);
                    data(3,2,nf) = 10^(v(3)/20)*exp(j*v(4)/180*pi);
                    data(3,3,nf) = 10^(v(5)/20)*exp(j*v(6)/180*pi);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
                if (dataform == 2)
                    data(1,1,nf) = v(2)*exp(j*v(3)/180*pi);
                    data(1,2,nf) = v(4)*exp(j*v(5)/180*pi);
                    data(1,3,nf) = v(6)*exp(j*v(7)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = v(1)*exp(j*v(2)/180*pi);
                    data(2,2,nf) = v(3)*exp(j*v(4)/180*pi);
                    data(2,3,nf) = v(5)*exp(j*v(6)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = v(1)*exp(j*v(2)/180*pi);
                    data(3,2,nf) = v(3)*exp(j*v(4)/180*pi);
                    data(3,3,nf) = v(5)*exp(j*v(6)/180*pi);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
                if (dataform == 3)
                    data(1,1,nf) = v(2)+j*v(3);
                    data(1,2,nf) = v(4)+j*v(5);
                    data(1,3,nf) = v(6)+j*v(7);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = v(1)+j*v(2);
                    data(2,2,nf) = v(3)+j*v(4);
                    data(2,3,nf) = v(5)+j*v(6);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = v(1)+j*v(2);
                    data(3,2,nf) = v(3)+j*v(4);
                    data(3,3,nf) = v(5)+j*v(6);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
            else
                line = fgetl(fid);
            end
            if isempty(line)
                line = fgetl(fid);
            end
        end
        freq = freq*freqin;
        npts = nf-1;

%Load s4p parameter
    elseif n == 4
        nf = 1;
        while ((line ~= -1)),
            v            =  sscanf(line,'%f');
            lenv = length(v);
            if (lenv == 9)
                freq(1,nf)     = v(1);
                if (dataform == 1)
                    data(1,1,nf) = 10^(v(2)/20)*exp(j*v(3)/180*pi);
                    data(1,2,nf) = 10^(v(4)/20)*exp(j*v(5)/180*pi);
                    data(1,3,nf) = 10^(v(6)/20)*exp(j*v(7)/180*pi);
                    data(1,4,nf) = 10^(v(8)/20)*exp(j*v(9)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = 10^(v(1)/20)*exp(j*v(2)/180*pi);
                    data(2,2,nf) = 10^(v(3)/20)*exp(j*v(4)/180*pi);
                    data(2,3,nf) = 10^(v(5)/20)*exp(j*v(6)/180*pi);
                    data(2,4,nf) = 10^(v(7)/20)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = 10^(v(1)/20)*exp(j*v(2)/180*pi);
                    data(3,2,nf) = 10^(v(3)/20)*exp(j*v(4)/180*pi);
                    data(3,3,nf) = 10^(v(5)/20)*exp(j*v(6)/180*pi);
                    data(3,4,nf) = 10^(v(7)/20)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(4,1,nf) = 10^(v(1)/20)*exp(j*v(2)/180*pi);
                    data(4,2,nf) = 10^(v(3)/20)*exp(j*v(4)/180*pi);
                    data(4,3,nf) = 10^(v(5)/20)*exp(j*v(6)/180*pi);
                    data(4,4,nf) = 10^(v(7)/20)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
                if (dataform == 2)
                    data(1,1,nf) = v(2)*exp(j*v(3)/180*pi);
                    data(1,2,nf) = v(4)*exp(j*v(5)/180*pi);
                    data(1,3,nf) = v(6)*exp(j*v(7)/180*pi);
                    data(1,4,nf) = v(8)*exp(j*v(9)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = v(1)*exp(j*v(2)/180*pi);
                    data(2,2,nf) = v(3)*exp(j*v(4)/180*pi);
                    data(2,3,nf) = v(5)*exp(j*v(6)/180*pi);
                    data(2,4,nf) = v(7)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = v(1)*exp(j*v(2)/180*pi);
                    data(3,2,nf) = v(3)*exp(j*v(4)/180*pi);
                    data(3,3,nf) = v(5)*exp(j*v(6)/180*pi);
                    data(3,4,nf) = v(7)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(4,1,nf) = v(1)*exp(j*v(2)/180*pi);
                    data(4,2,nf) = v(3)*exp(j*v(4)/180*pi);
                    data(4,3,nf) = v(5)*exp(j*v(6)/180*pi);
                    data(4,4,nf) = v(7)*exp(j*v(8)/180*pi);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
                if (dataform == 3)
                    data(1,1,nf) = v(2)+j*v(3);
                    data(1,2,nf) = v(4)+j*v(5);
                    data(1,3,nf) = v(6)+j*v(7);
                    data(1,4,nf) = v(8)+j*v(9);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(2,1,nf) = v(1)+j*v(2);
                    data(2,2,nf) = v(3)+j*v(4);
                    data(2,3,nf) = v(5)+j*v(6);
                    data(2,4,nf) = v(7)+j*v(8);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(3,1,nf) = v(1)+j*v(2);
                    data(3,2,nf) = v(3)+j*v(4);
                    data(3,3,nf) = v(5)+j*v(6);
                    data(3,4,nf) = v(7)+j*v(8);
                    line = fgetl(fid);
                    v            =  sscanf(line,'%f');
                    data(4,1,nf) = v(1)+j*v(2);
                    data(4,2,nf) = v(3)+j*v(4);
                    data(4,3,nf) = v(5)+j*v(6);
                    data(4,4,nf) = v(7)+j*v(8);
                    line = fgetl(fid);
                    nf = nf + 1;
                end
            else
                line = fgetl(fid);
            end
            if isempty(line)
                line = fgets(fid);
            end
        end
        freq = freq*freqin;
        npts = nf-1;
        
    % Modify the file formatting when the new format was recognized (mixed_normal = 0)
        if mixed_normal == 0
            data_temp = data;
            data_temp(1,3:4,:) = data(2,1:2,:);
            data_temp(2,1:2,:) = data(1,3:4,:);
            data_temp(3,3:4,:) = data(4,1:2,:);
            data_temp(4,1:2,:) = data(3,3:4,:);
            data = data_temp;
        end
            
%Load snp parameter for n>4
    elseif n > 4
        
        if rem(n,4) == 0
            max_row_in_line = n/4;
        else
            max_row_in_line = (floor(n/4)+1);
        end
        
        if (dataform == 1)
            nf = 0;
            while ((line ~= -1)), % Cycle for each frequency
                nf = nf + 1;
                v = sscanf(line,'%f');
            
                freq(1,nf)     = v(1);
                for row_index = 1:n % Cycle for each matrix row

                    col_index = 1;
                    for row_in_line = 1 : max_row_in_line % Cycle for each data row that own to the same matrix row (for n=11, s data are arranged in 3 rows)
                        
                        if row_in_line <= floor(n/4) % Data row with all the for parameter
                            line_size = 4;
                        else 
                            line_size = mod(n,4); % Data row with the last parameter of the current matrix row (for n=11 this line has only 3 elements)
                        end
                        
                        for col_index_parz=1:line_size % Cycle to read each single element in the data row

                            if row_index == 1 & row_in_line ==1
                                data(row_index,col_index,nf) = 10^( v(col_index_parz*2)/20 ) * exp( j* v(col_index_parz*2+1)/180*pi ); % Read data for the data row that has the frequency value
                            else
                                data(row_index,col_index,nf) = 10^ ( v(col_index_parz*2-1)/20 ) * exp( j*v(col_index_parz*2)/180*pi ); % Read data for all the other data rows
                            end
                            
                        col_index = col_index + 1; % Increment of the data matrix column
                        
                        end
                        line = fgetl(fid);
                        
                        if line == -1 % Do not scan the last line of the file
                            
                        elseif isempty(line) == 1 % This happens when blank line (that has just the line terminator) after data lines
                            line = fgets(fid); % Take the next line including the line terminator
                            while length(line) == 2 % Blank line of dimension 2 (just the line terminator)
                                line = fgets(fid);
                            end
                            if line == -1 % When reach the end of file after blank lines
                            else
                                v = sscanf(line,'%f');
                            end
                        else
                            v =  sscanf(line,'%f');
                        end

                    end
                     
                end
                 

            end
            freq = freq*freqin;
            npts = nf;
            
        elseif (dataform == 2)
            nf = 0;
            while ((line ~= -1)), % Cycle for each frequency
                nf = nf + 1;
                v = sscanf(line,'%f');
            
                freq(1,nf)     = v(1);
                for row_index = 1:n % Cycle for each matrix row

                    col_index = 1;
                    for row_in_line = 1 : max_row_in_line % Cycle for each data row that own to the same matrix row (for n=11, s data are arranged in 3 rows)
                        
                        if row_in_line <= floor(n/4) % Data row with all the for parameter
                            line_size = 4;
                        else 
                            line_size = mod(n,4); % Data row with the last parameter of the current matrix row (for n=11 this line has only 3 elements)
                        end
                        
                        for col_index_parz=1:line_size % Cycle to read each single element in the data row

                            if row_index == 1 & row_in_line ==1
                                data(row_index,col_index,nf) = v(col_index_parz*2) * exp( j*v(col_index_parz*2+1) /180*pi ); % Read data for the data row that has the frequency value
                            else
                                data(row_index,col_index,nf) = v(col_index_parz*2-1) * exp( j*v(col_index_parz*2) /180*pi ); % Read data for all the other data rows
                            end
                            
                        col_index = col_index + 1; % Increment of the data matrix column
                        
                        end
                        line = fgetl(fid);
                        
                        if line == -1 % Do not scan the last line of the file
                            
                        elseif isempty(line) == 1 % This happens when blank line (that has just the line terminator) after data lines
                            line = fgets(fid); % Take the next line including the line terminator
                            while length(line) == 2 % Blank line of dimension 2 (just the line terminator)
                                line = fgets(fid);
                            end
                            if line == -1 % When reach the end of file after blank lines
                            else
                                v = sscanf(line,'%f');
                            end
                        else
                            v =  sscanf(line,'%f');
                        end

                    end
                     
                end
                 

            end
            freq = freq*freqin;
            npts = nf;
       
            
        elseif (dataform == 3)
            nf = 0;
            while ((line ~= -1)), % Cycle for each frequency
                nf = nf + 1;
                v = sscanf(line,'%f');
            
                freq(1,nf)     = v(1);
                for row_index = 1:n % Cycle for each matrix row

                    col_index = 1;
                    for row_in_line = 1 : max_row_in_line % Cycle for each data row that own to the same matrix row (for n=11, s data are arranged in 3 rows)
                        
                        if row_in_line <= floor(n/4) % Data row with all the for parameter
                            line_size = 4;
                        else 
                            line_size = mod(n,4); % Data row with the last parameter of the current matrix row (for n=11 this line has only 3 elements)
                        end
                        
                        for col_index_parz=1:line_size % Cycle to read each single element in the data row

                            if row_index == 1 & row_in_line ==1
                                data(row_index,col_index,nf) = v(col_index_parz*2)+j*v(col_index_parz*2+1); % Read data for the data row that has the frequency value
                            else
                                data(row_index,col_index,nf) = v(col_index_parz*2-1)+j*v(col_index_parz*2); % Read data for all the other data rows
                            end
                            
                        col_index = col_index + 1; % Increment of the data matrix column
                        
                        end
                        line = fgetl(fid);
                        
                        if line == -1 % Do not scan the last line of the file
                            
                        elseif isempty(line) == 1 % This happens when blank line (that has just the line terminator) after data lines
                            line = fgets(fid); % Take the next line including the line terminator
                            while length(line) == 2 % Blank line of dimension 2 (just the line terminator)
                                line = fgets(fid);
                            end
                            if line == -1 % When reach the end of file after blank lines
                            else
                                v = sscanf(line,'%f');
                            end
                        else
                            v =  sscanf(line,'%f');
                        end

                    end
                     
                end
                 

            end
            freq = freq*freqin;
            npts = nf;
            
        end
    end
    freq = freq';                 
    fclose(fid);