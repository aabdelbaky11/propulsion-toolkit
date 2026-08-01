%NORMALSHOCK_CHECK  Validate normalShock.m against published table data.
%
%   Reference: Anderson, Modern Compressible Flow, Appendix A: Table A.2
%              (normal shock properties, gamma = 1.4)

clear; clc;

tol = 0.05;   % percent

%   M1     M2      p2/p1    rho2/rho1   T2/T1    p02/p01
ref = [
    1.00  1.0000   1.0000   1.0000   1.0000   1.0000
    1.50  0.7011   2.4583   1.8621   1.3202   0.9298
    2.00  0.5774   4.5000   2.6667   1.6875   0.7209
    2.50  0.5130   7.1250   3.3333   2.1375   0.4990
    3.00  0.4752  10.3333   3.8571   2.6790   0.3283
    3.50  0.4512  14.1250   4.2609   3.3151   0.2129
    4.00  0.4350  18.5000   4.5714   4.0469   0.1388
    4.50  0.4236  23.4583   4.8119   4.8751   0.0917
    5.00  0.4152  29.0000   5.0000   5.8000   0.0617
    ];

M1  = ref(:,1);
n   = numel(M1);
err = zeros(n,5);

fprintf('\nNormal shock relations vs Anderson Appendix B\n');
fprintf('%s\n', repmat('-',1,70));
fprintf('%6s %10s %10s %10s %10s %10s\n', ...
    'M1', 'M2', 'p2/p1', 'rho2/rho1', 'T2/T1', 'p02/p01');
fprintf('%6s %10s %10s %10s %10s %10s\n', ...
    '', '(% err)', '(% err)', '(% err)', '(% err)', '(% err)');
fprintf('%s\n', repmat('-',1,70));

for k = 1:n
    S = normalShock(M1(k));
    calc = [S.M2, S.p2_p1, S.rho2_rho1, S.T2_T1, S.p02_p01];
    err(k,:) = abs(calc - ref(k,2:6)) ./ ref(k,2:6) * 100;
    fprintf('%6.2f %10.4f %10.4f %10.4f %10.4f %10.4f\n', M1(k), err(k,:));
end

fprintf('%s\n', repmat('-',1,70));
fprintf('Max error: %.4f %%\n', max(err(:)));

if max(err(:)) < tol
    fprintf('PASS  all relations within %.2f %%\n', tol);
else
    fprintf('FAIL  see rows above\n');
end


% ---- inverse round-trip ------------------------------------------------

fprintf('\nInverse solver round-trip\n');
fprintf('%s\n', repmat('-',1,70));

names   = {'M2', 'p2_p1', 'rho2_rho1', 'T2_T1', 'p02_p01'};
maxBack = 0;

for k = 2:n
    S = normalShock(M1(k));
    for j = 1:numel(names)
        Mback   = normalShock(names{j}, S.(names{j}));
        maxBack = max(maxBack, abs(Mback - M1(k)));
    end
end

fprintf('Max |M1_recovered - M1|: %.3e\n', maxBack);


% ---- physical consistency checks ---------------------------------------

fprintf('\nPhysical checks\n');
fprintf('%s\n', repmat('-',1,70));

Msweep = 1.01:0.01:5;
S = normalShock(Msweep');

fprintf('M2 < 1 everywhere:              %s\n', passfail(all(S.M2 < 1)));
fprintf('p02/p01 <= 1 everywhere:        %s\n', passfail(all(S.p02_p01 <= 1)));
fprintf('p02/p01 decreasing with M1:     %s\n', passfail(all(diff(S.p02_p01) < 0)));
fprintf('T2/T1 = (p2/p1)(rho1/rho2):     %s\n', ...
    passfail(max(abs(S.T2_T1 - S.p2_p1./S.rho2_rho1)) < 1e-12));
fprintf('%s\n\n', repmat('-',1,70));


function s = passfail(tf)
if tf, s = 'PASS'; else, s = 'FAIL'; end
end