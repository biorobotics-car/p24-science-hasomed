
%%%%%%%%%%%%%   Authors: Tania Olmo Fajardo and Miguel Díaz Benito   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%   BioRobotics Group - Center for Automation and Robotics   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%  Spanish National Research Council (CSIC)   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%  July 2025   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mensaje = strhex2iop(msg)
    hexCells = strsplit(msg, ' ');
    ux = zeros(1, numel(hexCells));
    for i = 1:numel(hexCells)
        ux(i) = hex2dec(hexCells{i});
    end
    mensaje = uint8(ux);
end