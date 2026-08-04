function out = prandtlMeyer(varargin)
%PRANDTLMEYER  Prandtl-Meyer expansion for a calorically perfect gas.
%
%   FORWARD MODE
%   S = prandtlMeyer(M) returns
%       S.nu    Prandtl-Meyer angle, degrees
%       S.mu    Mach angle, degrees
%   for M >= 1. nu(M) is the angle through which a sonic flow must turn
%   to reach Mach M.
%
%   INVERSE MODE
%   M = prandtlMeyer('nu', value) solves nu(M) = value for M.
%
%   EXPANSION MODE
%   S = prandtlMeyer(M1, dtheta) turns a supersonic flow away from
%   itself through dtheta degrees and returns the downstream state:
%       S.M2        downstream Mach number
%       S.nu1,S.nu2 Prandtl-Meyer angles before and after
%       S.mu1,S.mu2 leading and trailing Mach wave angles
%       S.p2_p1     static pressure ratio
%       S.T2_T1     static temperature ratio
%       S.rho2_rho1 static density ratio
%       S.p02_p01   always exactly 1: the expansion is isentropic
%
%   Add a gas name as a final argument to use 'products' instead of 'air'.
%
%   The turn is limited. nu approaches a finite ceiling as M -> Inf
%   (130.45 deg for gamma = 1.4), so a flow at M1 can only turn
%   nu_max - nu(M1) before it would need infinite Mach number. Beyond
%   that the flow separates from the wall and a vacuum region forms.
%
%   Reference: Anderson, Modern Compressible Flow, Sec. 4.14.
%   Assumes steady, isentropic, calorically perfect gas.

    if isempty(varargin)
        error('prandtlMeyer:noInput', 'Supply a Mach number or a nu value.');
    end

    % --- inverse mode ----------------------------------------------------
    if ischar(varargin{1}) || isstring(varargin{1})
        if ~strcmpi(varargin{1}, 'nu')
            error('prandtlMeyer:unknownName', 'Only ''nu'' can be inverted.');
        end
        if numel(varargin) < 2
            error('prandtlMeyer:noValue', 'Inverse mode needs a value.');
        end
        gas = 'air';
        if numel(varargin) >= 3, gas = varargin{3}; end
        gamma = gasProps(gas);
        out = machFromNu(varargin{2}, gamma);
        return
    end

    M1 = varargin{1};
    if ~isreal(M1) || any(M1 < 1)
        error('prandtlMeyer:badMach', 'Mach number must be real and >= 1.');
    end

    % --- forward mode ----------------------------------------------------
    if numel(varargin) < 2 || ischar(varargin{2}) || isstring(varargin{2})
        gas = 'air';
        if numel(varargin) >= 2, gas = varargin{2}; end
        gamma  = gasProps(gas);
        out.nu = nuFromMach(M1, gamma);
        out.mu = asind(1./M1);
        return
    end

    % --- expansion mode --------------------------------------------------
    dtheta = varargin{2};
    gas    = 'air';
    if numel(varargin) >= 3, gas = varargin{3}; end
    if ~isscalar(M1) || ~isscalar(dtheta)
        error('prandtlMeyer:notScalar', 'Expansion mode takes scalars.');
    end
    if dtheta < 0
        error('prandtlMeyer:badTurn', ...
              'dtheta must be >= 0. A negative turn is a compression - use obliqueShock.');
    end

    gamma  = gasProps(gas);
    nu_max = 90*(sqrt((gamma+1)/(gamma-1)) - 1);

    out.nu1 = nuFromMach(M1, gamma);
    out.nu2 = out.nu1 + dtheta;
    out.dtheta      = dtheta;
    out.dtheta_max  = nu_max - out.nu1;

    if out.nu2 >= nu_max
        error('prandtlMeyer:overTurn', ...
              ['Turn of %.2f deg exceeds the maximum %.2f deg available ' ...
               'at M1 = %.3f (nu_max = %.2f deg).'], ...
              dtheta, out.dtheta_max, M1, nu_max);
    end

    out.M2 = machFromNu(out.nu2, gamma);

    out.mu1 = asind(1/M1);
    out.mu2 = asind(1/out.M2);

    % isentropic, so route the property ratios through stagnation values
    f1 = 1 + (gamma-1)/2 * M1^2;
    f2 = 1 + (gamma-1)/2 * out.M2^2;

    out.T2_T1     = f1 / f2;
    out.p2_p1     = (f1/f2)^( gamma/(gamma-1) );
    out.rho2_rho1 = (f1/f2)^( 1/(gamma-1) );
    out.p02_p01   = 1;

end


function nu = nuFromMach(M, gamma)
    a  = sqrt( (gamma+1)/(gamma-1) );
    b  = sqrt( M.^2 - 1 );
    nu = rad2deg( a .* atan(b./a) - atan(b) );
end


function M = machFromNu(nu, gamma)
    nu_max = 90*(sqrt((gamma+1)/(gamma-1)) - 1);
    if ~isscalar(nu) || ~isreal(nu) || nu < 0
        error('prandtlMeyer:badNu', 'nu must be a real scalar >= 0.');
    end
    if nu >= nu_max
        error('prandtlMeyer:nuTooLarge', ...
              'nu = %.3f exceeds the ceiling of %.3f deg for this gas.', ...
              nu, nu_max);
    end
    if nu == 0
        M = 1;
        return
    end
    M = fzero(@(m) nuFromMach(m, gamma) - nu, [1, 1e6]);
end