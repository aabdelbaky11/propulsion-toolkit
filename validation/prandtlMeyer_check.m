%PRANDTLMEYER_CHECK  Verify prandtlMeyer.m.
%
%   Anderson tabulates nu(M) and mu(M) in the Prandtl-Meyer appendix.
%   This script checks the forward function against transcribed rows,
%   round-trips the inverse, and asserts the properties that make an
%   expansion different from a shock.
%
%   Reference: Anderson, Modern Compressible Flow, Prandtl-Meyer table.

clear; clc;

tol = 0.05;   % percent

%    M       nu (deg)    mu (deg)
ref = [
    1.00      0.0000     90.0000
    1.50     11.9052     41.8103
    2.00     26.3798     30.0000
    2.50     39.1236     23.5782
    3.00     49.7573     19.4712
    4.00     65.7848     14.4775
    5.00     76.9202     11.5370
   10.00    102.3163      5.7392
];

M   = ref(:,1);
n   = numel(M);
err = zeros(n,2);

fprintf('\nPrandtl-Meyer function vs published table\n');
fprintf('%s\n', repmat('-',1,50));
fprintf('%8s %12s %12s\n', 'M', 'nu (% err)', 'mu (% err)');
fprintf('%s\n', repmat('-',1,50));

for k = 1:n
    S = prandtlMeyer(M(k));
    calc = [S.nu, S.mu];
    if M(k) == 1
        err(k,:) = [abs(calc(1)), abs(calc(2) - 90)/90*100];
    else
        err(k,:) = abs(calc - ref(k,2:3)) ./ ref(k,2:3) * 100;
    end
    fprintf('%8.2f %12.4f %12.4f\n', M(k), err(k,:));
end

fprintf('%s\n', repmat('-',1,50));
fprintf('Max error: %.4f %%\n', max(err(:)));
fprintf('%s\n', passfailLine(max(err(:)) < tol, tol));


% ---- inverse round-trip ------------------------------------------------

fprintf('\nInverse solver round-trip\n');
fprintf('%s\n', repmat('-',1,50));

Msweep  = 1.01:0.01:20;
maxBack = 0;
for m = Msweep
    S     = prandtlMeyer(m);
    mback = prandtlMeyer('nu', S.nu);
    maxBack = max(maxBack, abs(mback - m));
end
fprintf('M -> nu -> M over %d points, max err: %.3e\n', numel(Msweep), maxBack);


% ---- expansion properties ----------------------------------------------

fprintf('\nExpansion checks\n');
fprintf('%s\n', repmat('-',1,50));

isentropic_ok = true;
accelerates   = true;
pressureDrops = true;
waveSpreads   = true;

for m = [1.2 1.5 2 3 5]
    for dth = [1 5 10 20 30]
        E = prandtlMeyer(m, dth);
        isentropic_ok = isentropic_ok && (E.p02_p01 == 1);
        accelerates   = accelerates   && (E.M2 > m);
        pressureDrops = pressureDrops && (E.p2_p1 < 1);
        waveSpreads   = waveSpreads   && (E.mu2 < E.mu1);
    end
end

fprintf('p02/p01 = 1 exactly (isentropic):   %s\n', passfail(isentropic_ok));
fprintf('Flow always accelerates:            %s\n', passfail(accelerates));
fprintf('Static pressure always drops:       %s\n', passfail(pressureDrops));
fprintf('Mach waves fan outward:             %s\n', passfail(waveSpreads));

% additivity: two turns equal one combined turn
A = prandtlMeyer(2.0, 30);
B = prandtlMeyer(prandtlMeyer(2.0, 10).M2, 20);
addErr = abs(A.M2 - B.M2);
fprintf('Turning 10+20 equals turning 30:    %s  (%.2e)\n', ...
        passfail(addErr < 1e-9), addErr);

% ceiling is enforced
threw = false;
try
    prandtlMeyer(2.0, 110);
catch
    threw = true;
end
fprintf('Over-turn beyond nu_max rejected:   %s\n', passfail(threw));
fprintf('%s\n\n', repmat('-',1,50));


function s = passfail(tf)
    if tf, s = 'PASS'; else, s = 'FAIL'; end
end

function s = passfailLine(tf, tol)
    if tf
        s = sprintf('PASS  within %.2f %%', tol);
    else
        s = 'FAIL  see rows above';
    end
end