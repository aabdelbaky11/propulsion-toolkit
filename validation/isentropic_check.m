%ISENTROPIC_CHECK  Validate isentropic.m against published table data.
%
%   Reference: Anderson, Modern Compressible Flow, Appendix A
%              (isentropic flow properties, gamma = 1.4)
%
%   Checks the forward relations at 10 Mach numbers and confirms that
%   the inverse solver recovers the original Mach number.

clear; clc;

tol = 0.05;   % percent; flag anything worse

%   M      p0/p      T0/T     rho0/rho   A/A*
ref = [
    0.10    1.0070    1.0020    1.0050    5.8218
    0.20    1.0283    1.0080    1.0201    2.9635
    0.30    1.0644    1.0180    1.0456    2.0351
    0.50    1.1862    1.0500    1.1300    1.3398
    0.80    1.5243    1.1280    1.3510    1.0382
    1.00    1.8929    1.2000    1.5774    1.0000
    1.50    3.6710    1.4500    2.5317    1.1762
    2.00    7.8244    1.8000    4.3469    1.6875
    2.50   17.0859    2.2500    7.5938    2.6367
    3.00   36.7327    2.8000   13.1227    4.2346
    ];

M    = ref(:,1);
n    = numel(M);
err  = zeros(n,4);

fprintf('\nForward relations vs Anderson Appendix A\n');
fprintf('%s\n', repmat('-',1,62));
fprintf('%6s %10s %10s %10s %10s\n', 'M', 'p0/p', 'T0/T', 'rho0/rho', 'A/A*');
fprintf('%6s %10s %10s %10s %10s\n', '', '(% err)', '(% err)', '(% err)', '(% err)');
fprintf('%s\n', repmat('-',1,62));

for k = 1:n
    S = isentropic(M(k));
    calc = [S.p0_p, S.T0_T, S.rho0_rho, S.A_Astar];
    err(k,:) = abs(calc - ref(k,2:5)) ./ ref(k,2:5) * 100;
    fprintf('%6.2f %10.4f %10.4f %10.4f %10.4f\n', M(k), err(k,:));
end

fprintf('%s\n', repmat('-',1,62));
fprintf('Max error: %.4f %%\n', max(err(:)));

if max(err(:)) < tol
    fprintf('PASS  all forward relations within %.2f %%\n', tol);
else
    fprintf('FAIL  see rows above\n');
end


% ---- inverse round-trip ------------------------------------------------

fprintf('\nInverse solver round-trip\n');
fprintf('%s\n', repmat('-',1,62));

names   = {'p0_p', 'T0_T', 'rho0_rho'};
maxBack = 0;

for k = 1:n
    S = isentropic(M(k));
    for j = 1:numel(names)
        Mback = isentropic(names{j}, S.(names{j}));
        maxBack = max(maxBack, abs(Mback - M(k)));
    end
end

fprintf('Algebraic inverses, max |M_recovered - M|: %.3e\n', maxBack);

subErr = 0; supErr = 0;
for k = 1:n
    S = isentropic(M(k));
    if M(k) < 1
        subErr = max(subErr, abs(isentropic('A_Astar', S.A_Astar, 'sub') - M(k)));
    elseif M(k) > 1
        supErr = max(supErr, abs(isentropic('A_Astar', S.A_Astar, 'sup') - M(k)));
    end
end

fprintf('A/A* subsonic branch,  max error: %.3e\n', subErr);
fprintf('A/A* supersonic branch, max error: %.3e\n', supErr);
fprintf('%s\n\n', repmat('-',1,62));