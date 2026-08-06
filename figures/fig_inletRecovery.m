%FIG_INLETRECOVERY  Inlet total pressure recovery vs flight Mach number.
%
%   Generates figures/inlet_recovery.png
%
%   Four external compression configurations swept across the supersonic
%   flight envelope, against the MIL-E-5008B design standard. Ramp angles
%   are held fixed, so each curve ends where its shock system can no
%   longer stay attached - which is exactly why real inlets need variable
%   geometry.

clear; close all;

M0 = linspace(1.05, 3.5, 300);

configs = { ...
    'Normal shock (pitot)',  [],        [0.60 0.60 0.60] ; ...
    '1 ramp, 10\circ',       10,        [0.16 0.47 0.84] ; ...
    '2 ramps, 10\circ each', [10 10],   [0.20 0.60 0.35] ; ...
    '3 ramps, 8\circ each',  [8 8 8],   [0.85 0.33 0.10] };

fig = figure('Color','w','Units','inches','Position',[1 1 6.5 4.4]);
ax  = axes(fig); hold(ax,'on');

h = gobjects(size(configs,1),1);

for c = 1:size(configs,1)
    ramps = configs{c,2};
    pid   = nan(size(M0));

    for i = 1:numel(M0)
        M  = M0(i);
        pr = 1;
        ok = true;
        for k = 1:numel(ramps)
            if M <= 1, ok = false; break; end
            S = obliqueShock(M, ramps(k));
            if ~S.attached, ok = false; break; end
            pr = pr * S.p02_p01;
            M  = S.M2;
        end
        if ok && M >= 1
            pr = pr * normalShock(M).p02_p01;
            pid(i) = pr;
        end
    end

    h(c) = plot(ax, M0, pid, 'LineWidth', 1.8, 'Color', configs{c,3});
end

% MIL-E-5008B standard
mil = ones(size(M0));
sup = M0 > 1;
mil(sup) = 1 - 0.075*(M0(sup) - 1).^1.35;
hMil = plot(ax, M0, mil, 'k--', 'LineWidth', 1.2);

% mark the Mach 2 design point
plot(ax, [2 2], [0.6 1], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.9);
text(ax, 2.03, 0.635, 'design point', 'FontSize', 9, 'Color', [0.45 0.45 0.45]);

xlabel(ax, 'Flight Mach number,  M_0', 'FontSize', 11);
ylabel(ax, 'Total pressure recovery,  \pi_d = p_{02}/p_{00}', 'FontSize', 11);
title(ax, 'External compression inlet recovery (\gamma = 1.4, inviscid)', ...
    'FontSize', 12, 'FontWeight', 'normal');

legend(ax, [h; hMil], [configs(:,1); {'MIL-E-5008B standard'}], ...
    'Location','southwest','FontSize',9,'Box','off');

xlim(ax,[1 3.5]); ylim(ax,[0.6 1.02]);
grid(ax,'on'); ax.GridAlpha = 0.12;
ax.Box = 'off'; ax.TickDir = 'out'; ax.FontSize = 10; ax.LineWidth = 0.75;

exportgraphics(fig, 'figures/inlet_recovery.png', 'Resolution', 300);
fprintf('Wrote figures/inlet_recovery.png\n');