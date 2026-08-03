function out = obliqueShock(M1, theta_deg, varargin)
%OBLIQUESHOCK  Oblique shock relations from the theta-beta-M relation.
%
%   S = obliqueShock(M1, theta) solves for the weak-solution shock angle
%   at upstream Mach M1 and flow deflection theta (degrees), then applies
%   the normal shock relations to the component normal to the wave.
%
%       S.beta      shock angle, degrees
%       S.theta     deflection angle, degrees (echoed back)
%       S.M1n       upstream Mach normal to the shock
%       S.M2n       downstream Mach normal to the shock
%       S.M2        downstream Mach number
%       S.p2_p1     static pressure ratio
%       S.T2_T1     static temperature ratio
%       S.rho2_rho1 static density ratio
%       S.p02_p01   stagnation pressure ratio
%       S.attached  true if a solution exists
%       S.branch    'weak' or 'strong'
%
%   S = obliqueShock(M1, theta, 'strong') returns the strong solution.
%   S = obliqueShock(M1, theta, branch, gas) selects the gas.
%
%   If theta exceeds the maximum deflection for this M1, no attached
%   solution exists: the shock detaches and stands off as a curved bow
%   wave. S.attached is false, S.theta_max reports the limit, and the
%   remaining fields are NaN.
%
%   theta = 0 returns a Mach wave (beta = asin(1/M1), no property change).
%
%   Reference: Anderson, Modern Compressible Flow, Ch. 4.
%   Assumes steady, adiabatic, calorically perfect gas, straight wave.

    branch = 'weak';
    gas    = 'air';
    if numel(varargin) >= 1 && ~isempty(varargin{1}), branch = varargin{1}; end
    if numel(varargin) >= 2, gas = varargin{2}; end

    if ~isscalar(M1) || ~isreal(M1) || M1 <= 1
        error('obliqueShock:badMach', 'M1 must be a real scalar > 1.');
    end
    if ~isscalar(theta_deg) || ~isreal(theta_deg) || theta_deg < 0
        error('obliqueShock:badTheta', 'theta must be a real scalar >= 0.');
    end

    gamma = gasProps(gas);

    mu = asind(1/M1);                       % Mach angle: weakest possible wave
    [theta_max, beta_at_max] = maxDeflection(M1, gamma);

    out.theta     = theta_deg;
    out.theta_max = theta_max;

    if theta_deg > theta_max
        out.attached = false;
        out.branch   = 'detached';
        [out.beta, out.M1n, out.M2n, out.M2, ...
         out.p2_p1, out.T2_T1, out.rho2_rho1, out.p02_p01] = deal(NaN);
        return
    end

    out.attached = true;
    out.branch   = lower(branch);

    if theta_deg == 0
        out.beta = mu;
        if strcmpi(branch, 'strong'), out.beta = 90; end
    else
        f = @(b) thetaFromBeta(b, M1, gamma) - theta_deg;
        switch lower(branch)
            case {'weak'}
                bracket = [mu + 1e-9, beta_at_max];
            case {'strong'}
                bracket = [beta_at_max, 90 - 1e-9];
            otherwise
                error('obliqueShock:badBranch', ...
                      'Branch must be ''weak'' or ''strong''.');
        end
        out.beta = fzero(f, bracket);
    end

    % --- normal component, then reuse the normal shock solver ------------
    out.M1n = M1 * sind(out.beta);
    N = normalShock(out.M1n, gas);

    out.M2n        = N.M2;
    out.p2_p1      = N.p2_p1;
    out.T2_T1      = N.T2_T1;
    out.rho2_rho1  = N.rho2_rho1;
    out.p02_p01    = N.p02_p01;

    if theta_deg == 0
        out.M2 = M1;
    else
        out.M2 = out.M2n / sind(out.beta - theta_deg);
    end

end


function th = thetaFromBeta(beta_deg, M1, gamma)
%   The theta-beta-M relation, solved the easy direction.
    b   = deg2rad(beta_deg);
    num = M1^2 * sin(b)^2 - 1;
    den = M1^2 * (gamma + cos(2*b)) + 2;
    th  = rad2deg( atan( 2 * cot(b) * num / den ) );
end


function [theta_max, beta_at_max] = maxDeflection(M1, gamma)
%   Largest deflection a straight attached shock can turn the flow through.
    mu = asind(1/M1);
    negTheta = @(b) -thetaFromBeta(b, M1, gamma);
    beta_at_max = fminbnd(negTheta, mu + 1e-6, 90 - 1e-6, ...
                          optimset('TolX', 1e-10));
    theta_max = thetaFromBeta(beta_at_max, M1, gamma);
end