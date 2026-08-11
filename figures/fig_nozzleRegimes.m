%FIG_NOZZLEREGIMES  Pressure distribution through a CD nozzle, all regimes.
%
%   Generates figures/nozzle_regimes.png
%
%   One nozzle, six back pressures. The geometry never changes; only the
%   pressure downstream does. That is enough to move the flow through
%   every operating regime a converging-diverging nozzle has.

clear; close all;

x  = linspace(0, 1, 401)';
A  = 1 + (x - 0.3).^2/0.49;
p0 = 100;

L = nozzleFlow(A, x, p0, 50).limits;

cases = { ...
    98,                    'subsonic (not choked)',   [0.50 0.50 0.50] ; ...
    100*L.choke,           'just choked',             [0.30 0.30 0.30] ; ...
    88,                    'shock near throat',       [0.45 0.65 0.90] ; ...
    80,                    'shock mid-nozzle',        [0.16 0.47 0.84] ; ...
    100*L.shock_at_exit,   'shock at exit plane',     [0.55 0.35 0.75] ; ...
    100*L.design,          'design / over- / under-expanded', [0.85 0.33 0.10] };

fig = figure('Color','w','Units','inches','Position',[1 1 7 5.6]);

% --- upper panel: the nozzle shape ---------------------------------------
ax1 = subplot(3,1,1);
r = sqrt(A/pi);
fill(ax1, [x; flipud(x)], [r; -flipud(r)], [0.92 0.92 0.92], ...
    'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1);
hold(ax1,'on');
plot(ax1, [0.3 0.3], [-max(r) max(r)], ':', 'Color', [0.4 0.4 0.4]);
text(ax1, 0.31, 0.72*max(r), 'throat', 'FontSize', 9, 'Color', [0.35 0.35 0.35]);
xlim(ax1,[0 1]); ylim(ax1,[-1.1*max(r) 1.1*max(r)]); axis(ax1,'off');
ax1.Position(4) = ax1.Position(4)*0.8;
title(ax1, 'Converging-diverging nozzle,  A_e/A_t = 2.0', ...
    'FontSize', 12, 'FontWeight', 'normal');

% --- lower panel: pressure distributions ---------------------------------
ax2 = subplot(3,1,[2 3]);
hold(ax2,'on');
h = gobjects(size(cases,1),1);

for c = 1:size(cases,1)
    S = nozzleFlow(A, x, p0, cases{c,1});
    h(c) = plot(ax2, x, S.p/p0, 'LineWidth', 1.7, 'Color', cases{c,3});
end

plot(ax2, [0.3 0.3], [0 1], ':', 'Color', [0.6 0.6 0.6]);

xlabel(ax2, 'axial position,  x/L', 'FontSize', 11);
ylabel(ax2, 'p / p_0', 'FontSize', 11);
legend(ax2, h, cases(:,2), 'Location','southwest','FontSize',9,'Box','off');
xlim(ax2,[0 1]); ylim(ax2,[0 1.02]);
grid(ax2,'on'); ax2.GridAlpha = 0.12;
ax2.Box = 'off'; ax2.TickDir = 'out'; ax2.FontSize = 10;

exportgraphics(fig, 'figures/nozzle_regimes.png', 'Resolution', 300);
fprintf('Wrote figures/nozzle_regimes.png\n');