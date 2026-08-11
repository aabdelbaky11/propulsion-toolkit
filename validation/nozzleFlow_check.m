%NOZZLEFLOW_CHECK  Verify nozzleFlow.m.
%
%   No appendix tabulates nozzle operating regimes, so this script
%   verifies the solver against physics rather than published numbers:
%
%   1. Regime boundaries computed two independent ways
%   2. Mass flow conserved along the nozzle in every regime
%   3. Shock position solve reproduces the requested back pressure
%   4. Regime classification is correct on both sides of each boundary
%   5. Stagnation pressure constant except across the shock
%   6. Shock moves monotonically downstream as back pressure falls
%
%   Reference: Anderson, Modern Compressible Flow, Sec. 5.4.

clear; clc;

x  = linspace(0, 1, 401)';
A  = 1 + (x - 0.3).^2/0.49;
p0 = 100;

L = nozzleFlow(A, x, p0, 50).limits;

fprintf('\nnozzleFlow.m verification\n');
fprintf('%s\n', repmat('=',1,64));
fprintf('Nozzle: A_e/A_t = %.3f, throat at x = %.2f\n', ...
        A(end)/min(A), x(A == min(A)));
fprintf('\nRegime boundaries (pb/p0)\n');
fprintf('%s\n', repmat('-',1,64));
fprintf('  first choke        %.4f\n', L.choke);
fprintf('  shock at exit      %.4f\n', L.shock_at_exit);
fprintf('  design             %.4f\n', L.design);

% --- 1. boundaries cross-checked ----------------------------------------
ARe    = A(end)/min(A);
chk1   = 1/isentropic(areaMach(ARe,'sub')).p0_p;
Me_sup = areaMach(ARe,'sup');
chk3   = 1/isentropic(Me_sup).p0_p;
chk2   = normalShock(Me_sup).p2_p1 * chk3;
d = max(abs([L.choke-chk1, L.shock_at_exit-chk2, L.design-chk3]));
fprintf('\n%s\n', repmat('-',1,64));
fprintf('Boundaries reproduce independently:  %s  (%.2e)\n', ...
        passfail(d < 1e-12), d);

% --- 2. regime classification -------------------------------------------
tests = { ...
    0.99,                    'subsonic' ; ...
    L.choke*1.001,           'subsonic' ; ...
    L.choke*0.999,           'shock-in-nozzle' ; ...
    0.80,                    'shock-in-nozzle' ; ...
    L.shock_at_exit*1.001,   'shock-in-nozzle' ; ...
    L.shock_at_exit*0.999,   'overexpanded' ; ...
    0.30,                    'overexpanded' ; ...
    L.design,                'design' ; ...
    L.design*0.5,            'underexpanded' };

classOK = true;
fprintf('\nRegime classification\n');
fprintf('%s\n', repmat('-',1,64));
fprintf('%10s  %-20s %-20s\n', 'pb/p0', 'expected', 'got');
for k = 1:size(tests,1)
    S = nozzleFlow(A, x, p0, p0*tests{k,1});
    ok = strcmp(S.regime, tests{k,2});
    classOK = classOK && ok;
    fprintf('%10.4f  %-20s %-20s %s\n', tests{k,1}, tests{k,2}, S.regime, ...
            tickcross(ok));
end

% --- 3. mass flow conservation ------------------------------------------
%   rho*A*V / (rho0*a0*A*) is constant. Equivalently
%   A*M*(1 + (g-1)/2 M^2)^(-(g+1)/(2(g-1))) / p0_local is constant.
gamma = gasProps('air');
massOK = true; maxSpread = 0;
for pbr = [0.99 0.90 0.80 0.60 0.40 0.20 0.05]
    S = nozzleFlow(A, x, p0, p0*pbr);
    f = 1 + (gamma-1)/2*S.M.^2;
    mdot = S.p0_local .* S.A .* S.M .* f.^(-(gamma+1)/(2*(gamma-1)));
    spread = (max(mdot) - min(mdot))/mean(mdot);
    maxSpread = max(maxSpread, spread);
    massOK = massOK && spread < 1e-9;
end
fprintf('\n%s\n', repmat('-',1,64));
fprintf('Mass flow conserved along nozzle:    %s  (%.2e)\n', ...
        passfail(massOK), maxSpread);

% --- 4. shock solve reproduces pb ---------------------------------------
shockOK = true; maxPerr = 0;
for pbr = linspace(L.shock_at_exit*1.02, L.choke*0.98, 25)
    S = nozzleFlow(A, x, p0, p0*pbr);
    e = abs(S.pe - p0*pbr)/(p0*pbr);
    maxPerr = max(maxPerr, e);
    shockOK = shockOK && e < 1e-8;
end
fprintf('Shock solve matches pb (25 cases):   %s  (%.2e)\n', ...
        passfail(shockOK), maxPerr);

% --- 5. shock marches downstream ----------------------------------------
pbs = linspace(L.choke*0.98, L.shock_at_exit*1.02, 30);
xs  = arrayfun(@(r) nozzleFlow(A, x, p0, p0*r).x_shock, pbs);
fprintf('Shock moves downstream as pb falls:  %s\n', ...
        passfail(all(diff(xs) > 0)));

% --- 6. p0 constant except across the shock -----------------------------
S = nozzleFlow(A, x, p0, p0*0.80);
jumps = sum(abs(diff(S.p0_local)) > 1e-9);
fprintf('p0 drops exactly once (at shock):    %s  (%d jump)\n', ...
        passfail(jumps == 1), jumps);
fprintf('p0 never rises:                      %s\n', ...
        passfail(all(diff(S.p0_local) <= 1e-12)));

% --- 7. isentropic regimes lose no p0 -----------------------------------
isenOK = true;
for pbr = [0.99 0.30 L.design 0.02]
    S = nozzleFlow(A, x, p0, p0*pbr);
    isenOK = isenOK && all(abs(S.p0_local - p0) < 1e-9);
end
fprintf('No p0 loss when no shock present:    %s\n', passfail(isenOK));

allPass = d < 1e-12 && classOK && massOK && shockOK && all(diff(xs) > 0) && isenOK;
fprintf('%s\n', repmat('=',1,64));
if allPass
    fprintf('PASS  all checks\n\n');
else
    fprintf('FAIL  see above\n\n');
end


function s = passfail(tf)
    if tf, s = 'PASS'; else, s = 'FAIL'; end
end

function s = tickcross(tf)
    if tf, s = ''; else, s = '  <-- FAIL'; end
end