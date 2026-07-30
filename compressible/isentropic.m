function out = isentropic(varargin)
%ISENTROPIC  Isentropic flow relations for a calorically perfect gas.
%
%   FORWARD MODE
%   S = isentropic(M) returns a struct of property ratios at Mach M:
%       S.T0_T      stagnation / static temperature
%       S.p0_p      stagnation / static pressure
%       S.rho0_rho  stagnation / static density
%       S.A_Astar   local area / sonic throat area
%
%   S = isentropic(M, gas) selects 'air' (default) or 'products'.
%
%   INVERSE MODE
%   M = isentropic(name, value) solves for Mach number, where name is
%   'T0_T', 'p0_p', 'rho0_rho', or 'A_Astar'.
%
%   M = isentropic('A_Astar', value, branch) picks 'sub' (default) or
%   'sup'. The area relation has two roots; the other three have one.
%
%   Examples
%       S = isentropic(2.0);
%       M = isentropic('p0_p', 7.8244);
%       M = isentropic('A_Astar', 2.0, 'sup');
%
%   Assumes steady, isentropic, calorically perfect gas.

    if isempty(varargin)
        error('isentropic:noInput', ...
              'Supply a Mach number, or a ratio name and value.');
    end

    if isnumeric(varargin{1})
        M = varargin{1};
        gas = 'air';
        if numel(varargin) >= 2, gas = varargin{2}; end
        if any(M < 0) || ~isreal(M)
            error('isentropic:badMach', 'Mach number must be real and >= 0.');
        end
        gamma = gasProps(gas);
        out = forwardRatios(M, gamma);
    else
        if numel(varargin) < 2
            error('isentropic:noValue', 'Inverse mode needs a name and a value.');
        end
        name   = varargin{1};
        value  = varargin{2};
        branch = 'sub';
        gas    = 'air';
        if numel(varargin) >= 3 && ~isempty(varargin{3}), branch = varargin{3}; end
        if numel(varargin) >= 4, gas = varargin{4}; end
        gamma = gasProps(gas);
        out = inverseSolve(name, value, branch, gamma);
    end

end


function S = forwardRatios(M, gamma)

    f = 1 + (gamma - 1)/2 .* M.^2;

    S.T0_T     = f;
    S.p0_p     = f.^( gamma/(gamma - 1) );
    S.rho0_rho = f.^( 1/(gamma - 1) );
    S.A_Astar  = (1./M) .* ( (2/(gamma + 1)) .* f ).^( (gamma + 1)/(2*(gamma - 1)) );

end


function M = inverseSolve(name, value, branch, gamma)

    if ~isscalar(value) || ~isreal(value) || value < 1
        error('isentropic:badRatio', ...
              'Ratio must be a real scalar >= 1 (it equals 1 at M = 0 or M = 1).');
    end

    switch lower(name)

        case 't0_t'
            M = machFromTempRatio(value, gamma);

        case 'p0_p'
            M = machFromTempRatio( value^((gamma - 1)/gamma), gamma );

        case 'rho0_rho'
            M = machFromTempRatio( value^(gamma - 1), gamma );

        case 'a_astar'
            if value == 1
                M = 1;
                return
            end
            areaRatio = @(m) (1./m) .* ...
                ( (2/(gamma + 1)) .* (1 + (gamma - 1)/2 .* m.^2) ) ...
                .^( (gamma + 1)/(2*(gamma - 1)) );
            resid = @(m) areaRatio(m) - value;

            switch lower(branch)
                case {'sub', 'subsonic'}
                    bracket = [1e-6, 1];
                case {'sup', 'supersonic'}
                    bracket = [1, 50];
                otherwise
                    error('isentropic:badBranch', ...
                          'Branch must be ''sub'' or ''sup''.');
            end

            M = fzero(resid, bracket);

        otherwise
            error('isentropic:unknownRatio', ...
                  'Unknown ratio "%s". Use T0_T, p0_p, rho0_rho, or A_Astar.', name);
    end

end


function M = machFromTempRatio(T0_T, gamma)
    M = sqrt( 2/(gamma - 1) * (T0_T - 1) );
end