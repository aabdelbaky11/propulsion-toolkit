function out = areaMach(varargin)
%AREAMACH  Area-Mach relation for quasi-one-dimensional isentropic flow.
%
%   FORWARD MODE
%   ratio = areaMach(M) returns A/A* at Mach number M.
%
%   INVERSE MODE
%   M = areaMach(ratio, branch) solves A/A* = ratio for Mach number.
%   branch is 'sub' or 'sup'. The relation has a minimum of 1 at M = 1
%   and rises on both sides, so every ratio above 1 has two roots: one
%   subsonic, one supersonic. Which one is physical depends on the back
%   pressure, not on the geometry.
%
%   S = areaMach(ratio, 'both') returns a struct with both roots:
%       S.Msub, S.Msup, S.ratio
%
%   Add a gas name as a final argument for 'products' instead of 'air'.
%
%   A* is the area at which the flow would reach M = 1 with the same
%   stagnation conditions and mass flow. It is a reference area, not
%   necessarily a physical throat: an entirely subsonic duct still has a
%   well-defined A* even though no station in it is sonic.
%
%   Examples
%       areaMach(2.0)                  % 1.6875
%       areaMach(2.0, 'sub')           % 0.3059
%       areaMach(2.0, 'sup')           % 2.1972
%       S = areaMach(2.0, 'both')
%
%   Reference: Anderson, Modern Compressible Flow, Sec. 5.2.
%   Assumes steady, isentropic, calorically perfect gas, quasi-1D.

    if isempty(varargin)
        error('areaMach:noInput', 'Supply a Mach number, or a ratio and branch.');
    end

    % --- forward: one numeric argument (or numeric + gas) ----------------
    isForward = numel(varargin) == 1 || ...
                (numel(varargin) == 2 && (ischar(varargin{2}) || isstring(varargin{2})) ...
                 && ~any(strcmpi(varargin{2}, {'sub','subsonic','sup','supersonic','both'})));

    if isForward
        M   = varargin{1};
        gas = 'air';
        if numel(varargin) == 2, gas = varargin{2}; end
        if ~isreal(M) || any(M <= 0)
            error('areaMach:badMach', 'Mach number must be real and > 0.');
        end
        gamma = gasProps(gas);
        out = ratioFromMach(M, gamma);
        return
    end

    % --- inverse ---------------------------------------------------------
    ratio  = varargin{1};
    branch = varargin{2};
    gas    = 'air';
    if numel(varargin) >= 3, gas = varargin{3}; end

    if ~isscalar(ratio) || ~isreal(ratio)
        error('areaMach:badRatio', 'A/A* must be a real scalar.');
    end
    if ratio < 1
        error('areaMach:ratioBelowOne', ...
              ['A/A* = %.4f is below 1. The minimum area ratio is 1, ' ...
               'reached only at M = 1.'], ratio);
    end

    gamma = gasProps(gas);

    % At the sonic point both roots collapse onto M = 1. Solving there is
    % ill-conditioned - the curve is flat - so return the exact answer.
    if abs(ratio - 1) < 1e-12
        switch lower(branch)
            case {'sub','subsonic','sup','supersonic'}
                out = 1;
            case 'both'
                out = struct('Msub', 1, 'Msup', 1, 'ratio', 1);
            otherwise
                error('areaMach:badBranch', 'Branch must be ''sub'', ''sup'', or ''both''.');
        end
        return
    end

    resid = @(m) ratioFromMach(m, gamma) - ratio;

    switch lower(branch)
        case {'sub','subsonic'}
            out = fzero(resid, [subFloor(ratio, gamma), 1]);
        case {'sup','supersonic'}
            out = fzero(resid, [1, supCeiling(ratio, gamma)]);
        case 'both'
            out.Msub  = fzero(resid, [subFloor(ratio, gamma), 1]);
            out.Msup  = fzero(resid, [1, supCeiling(ratio, gamma)]);
            out.ratio = ratio;
        otherwise
            error('areaMach:badBranch', 'Branch must be ''sub'', ''sup'', or ''both''.');
    end

end


function r = ratioFromMach(M, gamma)
    f = 1 + (gamma-1)/2 .* M.^2;
    r = (1./M) .* ( (2/(gamma+1)) .* f ).^( (gamma+1)/(2*(gamma-1)) );
end


function lo = subFloor(ratio, gamma)
%   As M -> 0, A/A* -> Inf like 1/M, so a safe lower bracket scales with
%   the reciprocal of the ratio. Shrink until the residual brackets zero.
    lo = min(0.5, 0.5/ratio);
    while ratioFromMach(lo, gamma) < ratio && lo > realmin
        lo = lo/2;
    end
end


function hi = supCeiling(ratio, gamma)
%   Walk up until A/A* exceeds the target, then that is a valid bracket.
    hi = 2;
    while ratioFromMach(hi, gamma) < ratio && hi < 1e6
        hi = hi*2;
    end
end