%INLETRECOVERY  Total pressure recovery of external compression inlets.
%
%   Compares four ways of decelerating Mach 2.0 flow to subsonic:
%     0 ramps  - a single normal shock (a pitot inlet)
%     1 ramp   - one oblique shock, then a terminal normal shock
%     2 ramps  - two oblique shocks, then a terminal normal shock
%     3 ramps  - three oblique shocks, then a terminal normal shock
%
%   Every configuration does the same job: the flow arrives supersonic
%   and leaves subsonic, ready for the compressor face. What differs is
%   how much stagnation pressure survives the process.
%
%   Recovery is the product of the individual shock ratios:
%       pi_d = prod( p02/p01 )_i
%
%   Uses obliqueShock.m and normalShock.m.
%
%   Reference: Farokhi, Aircraft Propulsion, Sec. 6.11-6.12, 6.16.
%              Anderson, Modern Compressible Flow, Sec. 4.7.

clear; clc; close all;

M0 = 2.0;

configs = { ...
    'Normal shock (pitot)', [] ; ...
    '1 ramp, 10 deg',       10 ; ...
    '2 ramps, 10 deg each',[10 10] ; ...
    '3 ramps, 8 deg each', [8 8 8] };

fprintf('\nExternal compression inlet recovery at M0 = %.2f\n', M0);
fprintf('%s\n', repmat('=',1,72));

recovery = zeros(size(configs,1),1);

for c = 1:size(configs,1)
    name  = configs{c,1};
    ramps = configs{c,2};

    fprintf('\n%s\n', name);
    fprintf('%s\n', repmat('-',1,72));
    fprintf('%14s %8s %8s %8s %10s %10s\n', ...
        'wave', 'theta', 'beta', 'M in', 'M out', 'p02/p01');

    [pi_d, M] = deal(1, M0);

    for k = 1:numel(ramps)
        S = obliqueShock(M, ramps(k));
        fprintf('%14s %8.2f %8.2f %8.3f %10.3f %10.4f\n', ...
            sprintf('oblique %d', k), S.theta, S.beta, M, S.M2, S.p02_p01);
        pi_d = pi_d * S.p02_p01;
        M    = S.M2;
    end

    N = normalShock(M);
    fprintf('%14s %8s %8.2f %8.3f %10.3f %10.4f\n', ...
        'terminal NS', '-', 90, M, N.M2, N.p02_p01);
    pi_d = pi_d * N.p02_p01;

    fprintf('%s\n', repmat('-',1,72));
    fprintf('%54s %10.4f\n', 'total recovery  pi_d =', pi_d);

    recovery(c) = pi_d;
end

% --- summary -------------------------------------------------------------
fprintf('\n%s\n', repmat('=',1,72));
fprintf('%-26s %10s %14s\n', 'configuration', 'pi_d', 'vs pitot');
fprintf('%s\n', repmat('-',1,72));
for c = 1:size(configs,1)
    fprintf('%-26s %10.4f %13.1f%%\n', configs{c,1}, recovery(c), ...
        (recovery(c)/recovery(1) - 1)*100);
end
fprintf('%s\n', repmat('=',1,72));

% --- compare with the military standard ---------------------------------
%   MIL-E-5008B, for M0 > 1:  pi_d = 1 - 0.075*(M0 - 1)^1.35
milspec = 1 - 0.075*(M0 - 1)^1.35;
fprintf('\nMIL-E-5008B standard at M0 = %.2f:  pi_d = %.4f\n', M0, milspec);
fprintf('(An empirical design target, not a physical limit. It bundles in\n');
fprintf(' friction, boundary layer bleed, and subsonic diffuser losses that\n');
fprintf(' this inviscid shock-only model does not include.)\n\n');