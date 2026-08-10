%AREAMACH_CHECK  Verify areaMach.m.
%
%   The forward relation is already tabulated in Anderson's Appendix A,
%   so the reference rows below are the A/A* column from that table.
%   The inverse has no table, so it is verified by round-trip and by
%   agreement with isentropic.m, which implements the same relation
%   independently.
%
%   Reference: Anderson, Modern Compressible Flow, Appendix A.

clear; clc;

tol = 0.05;   % percent

%    M        A/A*
ref = [
    0.10    5.8218
    0.20    2.9635
    0.30    2.0351
    0.50    1.3398
    0.80    1.0382
    1.00    1.0000
    1.50    1.1762
    2.00    1.6875
    2.50    2.6367
    3.00    4.2346
    4.00   10.7188
    5.00   25.0000
];

M   = ref(:,1);
n   = numel(M);
err = zeros(n,1);

fprintf('\nArea-Mach relation vs Anderson Appendix A\n');
fprintf('%s\n', repmat('-',1,44));
fprintf('%8s %12s %12s %9s\n', 'M', 'computed', 'table', '% err');
fprintf('%s\n', repmat('-',1,44));

for k = 1:n
    r = areaMach(M(k));
    err(k) = abs(r - ref(k,2))/ref(k,2)*100;
    fprintf('%8.2f %12.4f %12.4f %9.4f\n', M(k), r, ref(k,2), err(k));
end

fprintf('%s\n', repmat('-',1,44));
fprintf('Max error: %.4f %%\n', max(err));
if max(err) < tol
    fprintf('PASS  within %.2f %%\n', tol);
else
    fprintf('FAIL  see rows above\n');
end


% ---- cross-check against isentropic.m ----------------------------------

fprintf('\nAgreement with isentropic.m\n');
fprintf('%s\n', repmat('-',1,44));
Msweep = [0.05:0.05:0.95, 1.05:0.05:10];
d = 0;
for m = Msweep
    d = max(d, abs(areaMach(m) - isentropic(m).A_Astar));
end
fprintf('Max difference over %d points: %.3e\n', numel(Msweep), d);


% ---- inverse round-trip ------------------------------------------------

fprintf('\nInverse round-trip\n');
fprintf('%s\n', repmat('-',1,44));

subErr = 0;
for m = 0.02:0.01:0.99
    subErr = max(subErr, abs(areaMach(areaMach(m), 'sub') - m));
end
fprintf('Subsonic branch,   %4d points, max err: %.3e\n', ...
        numel(0.02:0.01:0.99), subErr);

supErr = 0;
for m = 1.01:0.01:15
    supErr = max(supErr, abs(areaMach(areaMach(m), 'sup') - m));
end
fprintf('Supersonic branch, %4d points, max err: %.3e\n', ...
        numel(1.01:0.01:15), supErr);


% ---- behaviour near and at the sonic point -----------------------------

fprintf('\nSonic point handling\n');
fprintf('%s\n', repmat('-',1,44));

fprintf('A/A* at M = 1 is exactly 1:        %s\n', ...
        passfail(areaMach(1) == 1));

S = areaMach(1, 'both');
fprintf('Both roots collapse to 1 at A/A*=1: %s\n', ...
        passfail(S.Msub == 1 && S.Msup == 1));

% approach the singularity from above
nearOK = true;
for r = [1+1e-6, 1+1e-8, 1+1e-10]
    S = areaMach(r, 'both');
    nearOK = nearOK && S.Msub < 1 && S.Msup > 1 && ...
             abs(areaMach(S.Msub) - r) < 1e-9 && ...
             abs(areaMach(S.Msup) - r) < 1e-9;
end
fprintf('Roots stay separated near M = 1:   %s\n', passfail(nearOK));

% large ratios, where fixed brackets would fail
bigOK = true;
for r = [50, 500, 5000, 50000]
    S = areaMach(r, 'both');
    bigOK = bigOK && abs(areaMach(S.Msub)/r - 1) < 1e-6 && ...
                     abs(areaMach(S.Msup)/r - 1) < 1e-6;
end
fprintf('Adaptive brackets handle A/A* to 5e4: %s\n', passfail(bigOK));

% below the minimum is rejected
threw = false;
try, areaMach(0.5, 'sub'); catch, threw = true; end
fprintf('A/A* < 1 rejected:                 %s\n', passfail(threw));
fprintf('%s\n\n', repmat('-',1,44));


function s = passfail(tf)
    if tf, s = 'PASS'; else, s = 'FAIL'; end
end