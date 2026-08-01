function out = normalShock(varargin)
%NORMALSHOCK  Normal shock relations for a calorically perfect gas.
%
%   FORWARD MODE
%   S = normalShock(M1) returns a struct of jump conditions across a
%   stationary normal shock with upstream Mach number M1 >= 1:
%       S.M2        downstream Mach number (always < 1)
%       S.p2_p1     static pressure ratio
%       S.T2_T1     static temperature ratio
%       S.rho2_rho1 static density ratio
%       S.p02_p01   stagnation pressure ratio (the loss)
%
%   S = normalShock(M1, gas) selects 'air' (default) or 'products'.
%
%   INVERSE MODE
%   M1 = normalShock(name, value) recovers the upstream Mach number,
%   where name is 'M2', 'p2_p1', 'T2_T1', 'rho2_rho1', or 'p02_p01'.
%
%   Notes
%   Stagnation temperature is unchanged (T02 = T01): the shock is
%   adiabatic. Stagnation pressure always drops: the shock is
%   irreversible. That loss is what matters for inlet design.
%
%   Assumes steady, adiabatic, calorically perfect gas, no area change.

    if isempty(varargin)
        error('normalShock:noInput', ...
              'Supply an upstream Mach number, or a ratio name and value.');
    end

    if isnumeric(varargin{1})
        M1  = varargin{1};
        gas = 'air';
        if numel(varargin) >= 2, gas = varargin{2}; end
        if ~isreal(M1) || any(M1 < 1)
            error('normalShock:badMach', ...
                  'Upstream Mach number must be real and >= 1.');
        end
        gamma = gasProps(gas);
        out = jumpConditions(M1, gamma);
    else
        if numel(varargin) < 2
            error('normalShock:noValue', 'Inverse mode needs a name and a value.');
        end
        name  = varargin{1};
        value = varargin{2};
        gas   = 'air';
        if numel(varargin) >= 3, gas = varargin{3}; end
        gamma = gasProps(gas);
        out = inverseSolve(name, value, gamma);
    end

end


function S = jumpConditions(M1, gamma)

    gm1 = gamma - 1;
    gp1 = gamma + 1;
    M1sq = M1.^2;

    S.M2 = sqrt( (1 + gm1/2 .* M1sq) ./ (gamma .* M1sq - gm1/2) );

    S.p2_p1 = 1 + (2*gamma/gp1) .* (M1sq - 1);

    S.rho2_rho1 = (gp1 .* M1sq) ./ (2 + gm1 .* M1sq);

    S.T2_T1 = S.p2_p1 ./ S.rho2_rho1;

    S.p02_p01 = ( (gp1.*M1sq ./ (2 + gm1.*M1sq)).^(gamma/gm1) ) .* ...
                ( (gp1 ./ (2*gamma.*M1sq - gm1)).^(1/gm1) );

end


function M1 = inverseSolve(name, value, gamma)

    if ~isscalar(value) || ~isreal(value)
        error('normalShock:badValue', 'Value must be a real scalar.');
    end

    resid = @(m) subsref(jumpConditions(m, gamma), ...
                         struct('type','.','subs',lower_field(name))) - value;

    bracket = [1, 50];

    switch lower(name)
        case 'm2'
            if value <= 0 || value >= 1
                error('normalShock:badM2', ...
                      'Downstream Mach must be between 0 and 1.');
            end
        case {'p2_p1','t2_t1','rho2_rho1'}
            if value < 1
                error('normalShock:badRatio', ...
                      'Static ratios across a shock are >= 1.');
            end
        case 'p02_p01'
            if value <= 0 || value > 1
                error('normalShock:badLoss', ...
                      'Stagnation pressure ratio must be in (0, 1].');
            end
        otherwise
            error('normalShock:unknownRatio', ...
                  'Unknown quantity "%s".', name);
    end

    if abs(resid(1)) < 1e-12
        M1 = 1;
        return
    end

    M1 = fzero(resid, bracket);

end


function f = lower_field(name)
    switch lower(name)
        case 'm2',        f = 'M2';
        case 'p2_p1',     f = 'p2_p1';
        case 't2_t1',     f = 'T2_T1';
        case 'rho2_rho1', f = 'rho2_rho1';
        case 'p02_p01',   f = 'p02_p01';
    end
end