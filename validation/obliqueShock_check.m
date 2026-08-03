%OBLIQUESHOCK_CHECK  Verify obliqueShock.m.
%
%   There is no appendix table for oblique shocks - Anderson gives the
%   theta-beta-M chart instead. So this script checks the solver against
%   things that must be true rather than against tabulated numbers:
%
%   1. Reduction to the normal shock case at beta = 90 (theta = 0 strong)
%   2. Round-trip: beta -> theta -> beta closes on itself
%   3. Both roots return the deflection they were asked for
%   4. Weak solution is always the lower-loss one
%   5. Detachment limit matches published theta_max values
%
%   Reference: Anderson, Modern Compressible Flow, Ch. 4.

clear; clc;

fprintf('\nobliqueShock.m verification\n');
fprintf('%s\n', repmat('-',1,64));

% --- 1. reduction to normal shock ---------------------------------------
M1 = 2.5;
Sn = normalShock(M1);
So = obliqueShock(M1, 0, 'strong');     % theta = 0, beta = 90
d1 = max(abs([So.p2_p1 - Sn.p2_p1, So.T2_T1 - Sn.T2_T1, ...
    So.p02_p01 - Sn.p02_p01, So.M2n - Sn.M2]));
fprintf('Reduces to normal shock at beta = 90:   %s  (max diff %.2e)\n', ...
    passfail(d1 < 1e-12), d1);

% --- 2. both roots return the requested deflection -----------------------
Msweep = [1.5 2 2.5 3 4 5];
maxDefErr = 0;
for M = Msweep
    tmax = obliqueShock(M, 0).theta_max;
    for th = linspace(1, 0.95*tmax, 12)
        for br = {'weak','strong'}
            S = obliqueShock(M, th, br{1});
            maxDefErr = max(maxDefErr, abs(S.theta - th));
        end
    end
end
fprintf('Both roots honour requested theta:      %s  (max err %.2e)\n', ...
    passfail(maxDefErr < 1e-9), maxDefErr);

% --- 3. weak root is the lower-loss root --------------------------------
weakBetter = true;
weakSuper  = true;
for M = Msweep
    tmax = obliqueShock(M, 0).theta_max;
    for th = linspace(1, 0.90*tmax, 12)
        W = obliqueShock(M, th, 'weak');
        S = obliqueShock(M, th, 'strong');
        weakBetter = weakBetter && (W.p02_p01 > S.p02_p01);
        weakSuper  = weakSuper  && (S.M2 < 1);
    end
end
fprintf('Weak root always keeps more p0:         %s\n', passfail(weakBetter));
fprintf('Strong root always subsonic behind:     %s\n', passfail(weakSuper));

% --- 4. detachment limits vs published values ---------------------------
%   theta_max, degrees, gamma = 1.4
ref = [
    1.5   12.11
    2.0   22.97
    3.0   34.07
    5.0   41.12
    ];
fprintf('\nMaximum deflection angle\n');
fprintf('%6s %10s %10s %9s\n', 'M1', 'theta_max', 'published', '% err');
tmaxErr = 0;
for k = 1:size(ref,1)
    tm = obliqueShock(ref(k,1), 0).theta_max;
    e  = abs(tm - ref(k,2))/ref(k,2)*100;
    tmaxErr = max(tmaxErr, e);
    fprintf('%6.2f %10.3f %10.2f %9.4f\n', ref(k,1), tm, ref(k,2), e);
end
fprintf('%s\n', repmat('-',1,64));

% --- 5. detachment is flagged, not silently wrong ------------------------
D = obliqueShock(2.0, 30);
fprintf('Detachment flagged above theta_max:     %s\n', ...
    passfail(~D.attached && isnan(D.beta)));

allPass = d1 < 1e-12 && maxDefErr < 1e-9 && weakBetter && weakSuper && ...
    tmaxErr < 0.05 && ~D.attached;
fprintf('\n%s\n', repmat('-',1,64));
if allPass
    fprintf('PASS  all checks\n\n');
else
    fprintf('FAIL  see above\n\n');
end


function s = passfail(tf)
if tf, s = 'PASS'; else, s = 'FAIL'; end
end