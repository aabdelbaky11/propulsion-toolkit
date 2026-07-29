function [gamma, R, cp] = gasProps(gas)
%GASPROPS  Thermodynamic properties for a calorically perfect gas.
%   [gamma, R, cp] = gasProps(gas) returns the ratio of specific heats,
%   the specific gas constant [J/(kg*K)], and the specific heat at
%   constant pressure [J/(kg*K)].
%
%   gas : 'air'      - ambient air (default)
%         'products' - combustion products, post-burner
%
%   Assumes calorically perfect gas: cp and gamma constant with temperature.

if nargin < 1
    gas = 'air';
end

switch lower(gas)
    case 'air'
        gamma = 1.4;
        R     = 287.0;
    case 'products'
        gamma = 1.33;
        R     = 291.0;
    otherwise
        error('gasProps:unknownGas', ...
            'Unknown gas "%s". Use ''air'' or ''products''.', gas);
end

cp = gamma * R / (gamma - 1);

end