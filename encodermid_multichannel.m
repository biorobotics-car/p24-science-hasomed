
%%%%%%%%%%%%%   Authors: Tania Olmo Fajardo and Miguel Díaz Benito   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%   BioRobotics Group - Center for Automation and Robotics   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%  Spanish National Research Council (CSIC)   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%  July 2025   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function Final = encodermid_multichannel(channels, ramp, period, duration, current, numb_send)
tic;
% Initialize an array to store the modified results
modified_period = zeros(size(period));
% For loop to apply modification to every element
for i = 1:length(period)
    modified_period(i) = round(1000 / period(i));
end
period = modified_period;

% In this part, the predfined parameters are codified
numb_pts = 2; %Not always 2 but it seems that it's needed to initialize it like 2.


% Aquí se pasa de una lista de canales (p.e [1, 4, 5] a un vector de 0 y 1
% en donde se verifica si cada canal está activado (p.e [1, 0, 0, 1, 1, 0, 0, 0]
% Here we go from a list of channels (e.g. [1, 4, 5] to a vector of 0s and
% 1s where we verify which channels are active (e.g. [1, 0, 0, 1, 1, 0, 0, 0]
sequence = zeros(1, 8);
% Convert the used channels into bin index
for i = 1:length(channels)
    channel = channels(i);
    sequence(channel) = 1;
end


%1here we group the elements of the sequence (e.g. 10011000)
channel_bin = strrep(num2str(sequence), ' ', '');
total = "";
total_fixed = "";
count = 1;

for i = 1:length(channels)
    if period(i) == floor(period(i))
        chain_bin = strcat(dec2bin(period(i), 14), '00');
        period_bin = dec2bin(bin2dec(convertStringsToChars(chain_bin)), 16);
    else 
        chain_bin = strcat(dec2bin(period(i), 14), '00');
        base = dec2hex(bin2dec(convertStringsToChars(chain_bin)));
        period_bin = dec2bin(hex2dec(base) + hex2dec("02"), 16);
    end    
    Ml_channel_config = strcat(strcat(flip(channel_bin), dec2bin(numb_pts, 4), dec2bin(ramp(i), 4), period_bin), dec2bin(duration(i), 12), dec2bin((2*current(i) + 300), 10), '00'); 
    jk = convertStringsToChars(strcat(dec2bin(duration(i), 12)));
    jk = strcat("0000", jk);
    hexa = "";
    binary = convertStringsToChars(Ml_channel_config);
    for ia = 1:(strlength(binary)/8)
        lower = 1 + 8*(ia-1);
        upper = 8*ia;
        add = dec2hex(bin2dec(binary(lower:upper)), 2);
        hexa = hexa + add;
    end


    %This operation is done in hexadecimal
    codigo = dec2hex(hex2dec('B0B0') + 2 * current(i) .* hex2dec('3FC'));
    

    %This sequence seems to be always like this, at least in all our trials
    fixed = "000644B00" + dec2hex(bin2dec(jk), 4) + "4" + codigo(end-1:end);
 
    totalfixed = total + hexa + fixed;
    if count == 1
        total_fixed = total_fixed + totalfixed;
    else
        totalfixed = convertStringsToChars(totalfixed);
        total_fixed = total_fixed + "00" + totalfixed(3:end);
    end
    count = count + 1;
end

chain = total_fixed;

% Add a '0' at the end of the string; there must always be an even number of characters
% because one byte is represented by two hexadecimal letters, not one. In any case,
% this loop should never be entered if everything is working correctly.

if mod(strlength(chain), 2) == 1
    % Add a 0 at the end of the chain
    chain = strcat(chain, '0');
end

% Initialize a cell array to store the two-character groups
groups = cell(1, strlength(chain)/2);

% Loop to divide the chain in two-character groups
for i = 1:strlength(chain)/2
    % Calculate the indexes for start and end of the actual group
    index_start = (i-1)*2 + 1;
    index_end = i*2;
    
% This is VERY important: there are certain bytes reserved exclusively for
% indicating the start and end of a message (F0 and 0F), as well as a stuffing
% byte (81). So, if by chance the message data happens to contain one of these
% special bytes, it must be explicitly marked. To do this, an 81 is added and
% the byte is XORed with 01010101. In fact, the result of the XOR is always
% the same — for example, XORing F0 will always yield A5, and the same goes
% for the other two.
    group = extractBetween(chain, index_start, index_end);
    if group == "F0"
        group = "81A5";
    elseif group == "0F"
        group = "815A";
    elseif group == "81"
        group = "81D4"; 
    end

    % Almacenar el grupo en la celda
    groups{i} = group;
end

total_fixed = strcat(groups{:});


% Command_preffix
% Only the transmission number actually changes, since the other part
% ("0000000010") is the fixed command number for channel_config, which is
% always 2. It has been kept constant because this code is specifically
% intended for low-level pulse transmission (low_level).

command_preffix = dec2bin(numb_send, 6) + "0000100000";
command_preffix = dec2hex(bin2dec(command_preffix), 4);


% Checksum (see function checksumdef)
tic
packet = strcat(convertCharsToStrings(command_preffix), total_fixed, "00");
cks = checksumdef(convertStringsToChars(packet));
toc

% 81 is added because that is the stuffing byte, and according to the protocol,
% the checksum must be sent this way.
checksum = "81" + cks(1:2) + "81" + cks(3:4);


% Packet_length
% The behavior follows a pattern, but it's not very logical, so the approach has been
% based on observing the code for different message lengths. In short, it was derived
% experimentally.
list_len = ["44", "47", "49", "41", "40", "43", "42", "4D", "4C", "4F", "49", "49", "48", "4B", "4A", "75", "74", "77", "76", "71", "70", "73", "72", "7D", "7C", "7F", "7E", "79", "78", "7B", "7A",  "65", "64", "67", "66", "61", "60", "63", "62", "6D", "6C", "6F", "6E", "69", "68", "6B", "6A",  "15", "14", "17", "16", "11", "10", "13", "12", "1D", "1C", "1F", "1E", "19", "18", "1B", "1A", "05", "04", "07", "06", "01", "00", "03", "02", "0D", "0C", "0F", "0E", "09", "08", "0B", "0A","35", "34", "37", "36", "31", "30", "33", "32", "3D", "3C", "3F", "3E", "39", "38", "3B", "3A", "25", "24", "27", "26", "21", "20", "23", "22", "2D", "2C", "2F", "2E", "29", "28", "2B", "2A", "D5", "D4", "D7", "D6", "D1", "D0", "D3", "D2", "DD", "DC", "DF", "DE", "D9", "D8", "DB", "DA", "C5", "C4", "C7", "C6", "C1", "C0", "C3", "C2", "CD", "CC", "CF", "CE", "C9", "C8", "CB", "CA"];
length = (strlength('f0' + checksum + command_preffix + total_fixed + '0f') + 8)/2;


% The length is adjusted by subtracting 15 because the list doesn't start at zero.
% For instance, code 44 is the first entry in the list, but it actually represents
% a packet length of 16 bytes.
p_length = "815581" + list_len(length-15);

% All the collected information is gathered together.
Final = strcat('F0', p_length, checksum, command_preffix,  total_fixed, '000F');

% This part of the code transforms the data so that
% it can be sent correctly to the stimulator (it must be a uint8 vector,
% where each element of the vector is, in decimal numbers, one of the
% bytes of the message).
hexCells = regexp(Final, '.{2}', 'match');
ux = zeros(1, numel(hexCells));
for i = 1:numel(hexCells)
    ux(i) = hex2dec(hexCells{i});
end
Final = uint8(ux);
toc
end
