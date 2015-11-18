function marlocbleCoorlocd = marlocbleCoorlocdinates_v2(rloc,rcirc,dim)
% Gregory Poore
% BME 462

%% Marlocble Coorlocdinates
marlocbleCoorlocd = ...
    [0 0 0 rcirc;
     0 2*rloc 0 rcirc;
     0 4*rloc 0 rcirc;
     0 6*rloc 0 rcirc;
     0 8*rloc 0 rcirc;
     
     0 -2*rloc 0 rcirc;
     0 -4*rloc 0 rcirc;
     0 -6*rloc 0 rcirc;
     0 -8*rloc 0 rcirc;
     
     rloc*sqrt(3) rloc 0 rcirc;
     rloc*sqrt(3) 3*rloc 0 rcirc;
     rloc*sqrt(3) 5*rloc 0 rcirc;
     rloc*sqrt(3) 7*rloc 0 rcirc;
     
     rloc*sqrt(3) -rloc 0 rcirc;
     rloc*sqrt(3) -3*rloc 0 rcirc;
     rloc*sqrt(3) -5*rloc 0 rcirc;
     rloc*sqrt(3) -7*rloc 0 rcirc;
     
     2*rloc*sqrt(3) 0 0 rcirc;
     2*rloc*sqrt(3) 2*rloc 0 rcirc;
     2*rloc*sqrt(3) 4*rloc 0 rcirc;
     2*rloc*sqrt(3) 6*rloc 0 rcirc;
     
     2*rloc*sqrt(3) -2*rloc 0 rcirc;
     2*rloc*sqrt(3) -4*rloc 0 rcirc;
     2*rloc*sqrt(3) -6*rloc 0 rcirc;
     
     3*rloc*sqrt(3) rloc 0 rcirc;
     3*rloc*sqrt(3) 3*rloc 0 rcirc;
     3*rloc*sqrt(3) 5*rloc 0 rcirc;
     
     3*rloc*sqrt(3) -rloc 0 rcirc;
     3*rloc*sqrt(3) -3*rloc 0 rcirc;
     3*rloc*sqrt(3) -5*rloc 0 rcirc;
     
     4*rloc*sqrt(3) 0 0 rcirc;
     4*rloc*sqrt(3) 2*rloc 0 rcirc;
     4*rloc*sqrt(3) 4*rloc 0 rcirc;
     
     4*rloc*sqrt(3) -2*rloc 0 rcirc;
     4*rloc*sqrt(3) -4*rloc 0 rcirc;
     
     % Negative x dirlocection
     -rloc*sqrt(3) rloc 0 rcirc;
     -rloc*sqrt(3) 3*rloc 0 rcirc;
     -rloc*sqrt(3) 5*rloc 0 rcirc;
     -rloc*sqrt(3) 7*rloc 0 rcirc;
     
     -rloc*sqrt(3) -rloc 0 rcirc;
     -rloc*sqrt(3) -3*rloc 0 rcirc;
     -rloc*sqrt(3) -5*rloc 0 rcirc;
     -rloc*sqrt(3) -7*rloc 0 rcirc;
     
     -2*rloc*sqrt(3) 0 0 rcirc;
     -2*rloc*sqrt(3) 2*rloc 0 rcirc;
     -2*rloc*sqrt(3) 4*rloc 0 rcirc;
     -2*rloc*sqrt(3) 6*rloc 0 rcirc;
     
     -2*rloc*sqrt(3) -2*rloc 0 rcirc;
     -2*rloc*sqrt(3) -4*rloc 0 rcirc;
     -2*rloc*sqrt(3) -6*rloc 0 rcirc;
     
     -3*rloc*sqrt(3) rloc 0 rcirc;
     -3*rloc*sqrt(3) 3*rloc 0 rcirc;
     -3*rloc*sqrt(3) 5*rloc 0 rcirc;
     
     -3*rloc*sqrt(3) -rloc 0 rcirc;
     -3*rloc*sqrt(3) -3*rloc 0 rcirc;
     -3*rloc*sqrt(3) -5*rloc 0 rcirc;
     
     -4*rloc*sqrt(3) 0 0 rcirc;
     -4*rloc*sqrt(3) 2*rloc 0 rcirc;
     -4*rloc*sqrt(3) 4*rloc 0 rcirc;
     
     -4*rloc*sqrt(3) -2*rloc 0 rcirc;
     -4*rloc*sqrt(3) -4*rloc 0 rcirc]

    if(dim==2)
    marlocbleCoorlocd(:,3) = [];
end
end