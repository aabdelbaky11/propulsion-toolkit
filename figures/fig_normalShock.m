%FIG_NORMALSHOCK  Normal shock: downstream Mach and total pressure loss.
%
%   Generates figures/normalShock_properties.png
%
%   Two quantities across a stationary normal shock in air (gamma = 1.4):
%   the downstream Mach number, and the fraction of stagnation pressure
%   that survives. The second is the number that drives inlet design.

clear; close all;

M1 = linspace(1, 5, 400);
S  = normalShock(M1');

% --- style ---------------------------------------------------------------
cMach = [0.16 0.47 0.84];   % blue
cLoss = [0.85 0.33 0.10];   % orange
lw    = 1.8;
fs    = 11;

fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1 1 6.5 4.2]);
ax  = axes(fig);
hold(ax, 'on');

p1 = plot(ax, M1, S.M2,      'LineWidth', lw, 'Color', cMach);
p2 = plot(ax, M1, S.p02_p01, 'LineWidth', lw, 'Color', cLoss, 'LineStyle', '--');

% --- annotate the Mach 2 case -------------------------------------------
S2 = normalShock(2.0);
plot(ax, 2, S2.p02_p01, 'o', 'MarkerSize', 6, ...
    'MarkerFaceColor', cLoss, 'MarkerEdgeColor', 'w', 'LineWidth', 1);
text(ax, 2.12, S2.p02_p01 + 0.04, ...
    sprintf('M_1 = 2:  %.1f%% of p_0 lost', 100*(1 - S2.p02_p01)), ...
    'FontSize', fs - 1, 'Color', cLoss*0.8);

% --- axes ----------------------------------------------------------------
xlabel(ax, 'Upstream Mach number,  M_1', 'FontSize', fs);
ylabel(ax, 'Ratio  [–]', 'FontSize', fs);
title(ax,  'Normal shock in air (\gamma = 1.4)', ...
    'FontSize', fs + 1, 'FontWeight', 'normal');

legend(ax, [p1 p2], {'M_2  (downstream Mach)', 'p_{02}/p_{01}  (total pressure ratio)'}, ...
    'Location', 'northeast', 'FontSize', fs - 1, 'Box', 'off');

xlim(ax, [1 5]);
ylim(ax, [0 1.05]);
grid(ax, 'on');
ax.GridAlpha   = 0.12;
ax.FontSize    = fs - 1;
ax.Box         = 'off';
ax.TickDir     = 'out';
ax.LineWidth   = 0.75;

% --- export --------------------------------------------------------------
exportgraphics(fig, 'figures/normalShock_properties.png', 'Resolution', 300);
fprintf('Wrote figures/normalShock_properties.png\n');