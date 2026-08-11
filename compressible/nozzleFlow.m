function out = nozzleFlow(A, x, p0, pb, varargin)
%NOZZLEFLOW  Quasi-1D flow through a converging-diverging nozzle.
%
%   S = nozzleFlow(A, x, p0, pb) solves the flow through a nozzle whose
%   area distribution is A at stations x, driven by stagnation pressure
%   p0 against back pressure pb (same units).
%
%   Returns
%       S.regime      one of the six strings listed below
%       S.M           Mach number at each station
%       S.p           static pressure at each station
%       S.p0_local    local stagnation pressure (drops only across a shock)
%       S.T_T0        static / stagnation temperature at each station
%       S.choked      true if the throat is sonic
%       S.Me          exit Mach number
%       S.pe          exit static pressure
%       S.x_shock     shock position, NaN if there is no internal shock
%       S.M_shock     Mach number just upstream of the shock
%       S.limits      struct of the regime boundary pressure ratios
%
%   Regimes, in order of decreasing back pressure:
%       'subsonic'      venturi flow, never sonic, pe = pb
%       'choked-subsonic'  throat sonic, diverging section decelerates
%       'shock-in-nozzle'  normal shock stands inside the diverging section
%       'overexpanded'     pe < pb, oblique shocks outside the exit
%       'design'           pe = pb, fully expanded, no external waves
%       'underexpanded'    pe > pb, expansion fan outside the exit
%
%   Only the internal solution is computed. In the overexpanded and
%   underexpanded regimes the flow inside the nozzle is identical to the
%   design case - the difference happens downstream of the exit plane.
%
%   Uses areaMach.m, isentropic.m, normalShock.m.
%
%   Reference: Anderson, Modern Compressible Flow, Sec. 5.4.
%              Farokhi, Aircraft Propulsion, Sec. 6.21, 6.28.
%   Assumes steady, adiabatic, quasi-1D, calorically perfect gas.

    gas = 'air';
    if numel(varargin) >= 1, gas = varargin{1}; end
    gamma = gasProps(gas);

    A = A(:);  x = x(:);
    if numel(A) ~= numel(x)
        error('nozzleFlow:sizeMismatch', 'A and x must be the same length.');
    end
    if any(A <= 0)
        error('nozzleFlow:badArea', 'Areas must be positive.');
    end
    if p0 <= 0 || pb < 0
        error('nozzleFlow:badPressure', 'p0 must be > 0 and pb >= 0.');
    end

    [At, it] = min(A);
    Ae = A(end);
    n  = numel(A);

    if it == n
        error('nozzleFlow:noThroat', ...
              'The minimum area is at the exit - this is a convergent nozzle.');
    end

    ARe = Ae/At;

    % --- regime boundaries -----------------------------------------------
    Me_sub = areaMach(ARe, 'sub');      % exit Mach if choked, subsonic branch
    Me_sup = areaMach(ARe, 'sup');      % exit Mach if fully supersonic

    r_choke  = 1/isentropic(Me_sub).p0_p;   % highest pb/p0 that still chokes
    r_design = 1/isentropic(Me_sup).p0_p;   % perfectly expanded

    Nexit    = normalShock(Me_sup);
    r_shockE = Nexit.p2_p1 * r_design;      % shock sitting at the exit plane

    out.limits = struct('choke', r_choke, 'shock_at_exit', r_shockE, ...
                        'design', r_design);

    r = pb/p0;

    out.x_shock = NaN;
    out.M_shock = NaN;

    % --- pick the regime --------------------------------------------------
    if r >= r_choke
        % Not choked. Subsonic everywhere, exit pressure equals back pressure.
        out.regime = 'subsonic';
        out.choked = false;

        Me    = isentropic('p0_p', p0/pb);
        Astar = Ae / areaMach(Me);          % A* implied by the exit state
        out.M = arrayfun(@(a) areaMach(a/Astar, 'sub'), A);

        S = isentropic(out.M);
        out.p        = p0 ./ S.p0_p;
        out.p0_local = repmat(p0, n, 1);
        out.T_T0     = 1 ./ S.T0_T;

    else
        out.choked = true;

        if abs(r - r_choke) < 1e-12
            out.regime = 'choked-subsonic';
            branchAfter = 'sub';
        elseif r > r_shockE
            out.regime = 'shock-in-nozzle';
            branchAfter = [];
        elseif r > r_design
            out.regime = 'overexpanded';
            branchAfter = 'sup';
        elseif abs(r - r_design) < 1e-9
            out.regime = 'design';
            branchAfter = 'sup';
        else
            out.regime = 'underexpanded';
            branchAfter = 'sup';
        end

        if ~isempty(branchAfter)
            % No internal shock: isentropic from p0 all the way through.
            out.M = zeros(n,1);
            for k = 1:n
                if k <= it
                    out.M(k) = areaMach(A(k)/At, 'sub');
                else
                    out.M(k) = areaMach(A(k)/At, branchAfter);
                end
            end
            S = isentropic(out.M);
            out.p        = p0 ./ S.p0_p;
            out.p0_local = repmat(p0, n, 1);
            out.T_T0     = 1 ./ S.T0_T;

        else
            % --- shock inside the diverging section ----------------------
            %   Find the area at which a normal shock makes the exit
            %   pressure equal the back pressure.
            f = @(As) exitPressure(As, At, Ae, p0, gamma) - pb;

            Alo = At*(1 + 1e-9);
            Ahi = Ae;
            As  = fzero(f, [Alo, Ahi]);

            M1s = areaMach(As/At, 'sup');
            N   = normalShock(M1s);

            p0_after = p0 * N.p02_p01;
            Astar2   = As / areaMach(N.M2);   % new sonic reference downstream

            out.M_shock = M1s;
            out.x_shock = interp1(A(it:end), x(it:end), As, 'linear');

            out.M        = zeros(n,1);
            out.p0_local = zeros(n,1);

            for k = 1:n
                if k <= it
                    out.M(k)        = areaMach(A(k)/At, 'sub');
                    out.p0_local(k) = p0;
                elseif A(k) < As
                    out.M(k)        = areaMach(A(k)/At, 'sup');
                    out.p0_local(k) = p0;
                else
                    out.M(k)        = areaMach(A(k)/Astar2, 'sub');
                    out.p0_local(k) = p0_after;
                end
            end

            S        = isentropic(out.M);
            out.p    = out.p0_local ./ S.p0_p;
            out.T_T0 = 1 ./ S.T0_T;
        end
    end

    out.Me = out.M(end);
    out.pe = out.p(end);
    out.pb = pb;
    out.p0 = p0;
    out.x  = x;
    out.A  = A;

end


function pe = exitPressure(As, At, Ae, p0, gamma) %#ok<INUSD>
%   Exit static pressure given a normal shock at area As in the
%   diverging section. Used as the residual for the shock-position solve.
    M1s      = areaMach(As/At, 'sup');
    N        = normalShock(M1s);
    p0_after = p0 * N.p02_p01;
    Astar2   = As / areaMach(N.M2);
    Me       = areaMach(Ae/Astar2, 'sub');
    pe       = p0_after / isentropic(Me).p0_p;
end