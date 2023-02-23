clearvars
close all;  
clc; 
format long;
global P lP

%% numerical config
age_max = 100*365; % max ages in days
P.age_max = age_max;
dt = 5; % time/age step size in days, default = 5;
da = dt;
a = (0:da:age_max)';
na = length(a);

P.a = a;
P.na = na;
P.da = da;
P.dt = dt;

Malaria_parameters_baseline;
Malaria_parameters_transform;
Malaria_parameters_transform_vac;

lQ = {'year5-D-process'}; % metric to compare
tfinal = 5*365;
lP_list = {'v0'}; % etas - sterile, etab - blood stage

%% initial condition - numerical EE with reset, no vaccine
P.v0 = 0;
Malaria_parameters_transform;
Malaria_parameters_transform_vac;
[SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0] = age_structured_Malaria_IC_vac('EE_reset');
% soln = solution_pack(SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0);
% QOI_initial = QOI_save(lQ,soln);

%% baseline run
disp('baseline run ---');
P.z = 0; % RTS,S only (z=0)
P.v0 = 15; 
Malaria_parameters_transform;
Malaria_parameters_transform_vac;

if strcmp(lQ{1}(1:5),'year5')
    [SH, EH, DH, AH, VH, UH, SM, EM, IM, Cm, Cac, Cv, Ctot, MH] = ...
        age_structured_Malaria_vac(P.da,P.na,tfinal, SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0);
    soln = solution_pack(SH, EH, DH, AH, VH, UH, SM, EM, IM, Cm, Cac, Cv, Ctot, MH);
end
% P_baseline = P.(lP);
Q_baseline = QOI_save(lQ,soln);

%% comparison runs
P.z = 1; % blood stage only (z=1)
P.v0_lower = 0;
P.v0_upper = 1000;
Malaria_parameters_transform;
Malaria_parameters_transform_vac;

tic
for iP = 1:length(lP_list)
    lP = lP_list{iP};   
    
    %% extended SA
    P_lower = P.([lP,'_lower']);
    P_upper = P.([lP,'_upper']);
    ngrid = 11; % total number of grid points
    
    PH_temp = zeros(1,ngrid);
    IM_temp = zeros(1,ngrid);
    save_sol_UH = zeros(na,ngrid);
    save_sol_Cac = zeros(na,ngrid);
    save_sol_Cv = zeros(na,ngrid);
    save_sol_VH = zeros(na,ngrid);
    save_sol_SH = zeros(na,ngrid);
    save_sol_AH = zeros(na,ngrid);
    save_sol_DH = zeros(na,ngrid);
    save_sol_Ctot = zeros(na,ngrid);
    
    % allocation
    P_vals = linspace(P_lower,P_upper,ngrid)';
    Q_vals = NaN(length(P_vals),length(Q_baseline));
    
    for i=1:ngrid
        display(['I am working on simulation ', num2str(i)])
        P.(lP) = P_vals(i);
        Malaria_parameters_transform;
        Malaria_parameters_transform_vac;
        if strcmp(lQ{1}(1:5),'year5')
            [SH, EH, DH, AH, VH, UH, SM, EM, IM, Cm, Cac, Cv, Ctot, MH] = ...
                age_structured_Malaria_vac(P.da,P.na,tfinal, SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0);
            soln = solution_pack(SH, EH, DH, AH, VH, UH, SM, EM, IM, Cm, Cac, Cv, Ctot, MH);
        end
        PH_temp(i) = sum(SH(:,end) + EH(:,end) + DH(:,end) + AH(:,end) + VH(:,end) + UH(:,end));
        IM_temp(i) = IM(end);
        save_sol_UH(:,i) = UH(:,end);
        save_sol_VH(:,i) = VH(:,end);
        save_sol_SH(:,i) = SH(:,end);
        save_sol_AH(:,i) = AH(:,end);
        save_sol_DH(:,i) = DH(:,end);
        save_sol_Cac(:,i) = Cac(:,end);
        save_sol_Cv(:,i) = Cv(:,end);
        save_sol_Ctot(:,i) = Ctot(:,end);
        
        Q_vals(i,:) = QOI_save(lQ,soln);
    end
    
end
toc
%% heatmap plot of final population distributions
figure;
imagesc(save_sol_Cac./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{C}_{ac}$ final distributions');

figure;
imagesc(save_sol_Cv./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{C}_v$ final distributions');

figure;
imagesc(save_sol_Ctot./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{C}_{tot}$ final distributions');


figure;
imagesc(save_sol_VH./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{V}_H$ final distributions');

figure;
imagesc(save_sol_SH./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{S}_H$ final distributions');

figure;
imagesc(save_sol_AH./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{A}_H$ final distributions');

figure;
imagesc(save_sol_DH./PH_temp);
set(gca,'YDir','normal')
xlabel(lP);
ylabel('age');
set(gca,'xtickLabel',compose('%d',P_vals(xticks)));
set(gca,'ytickLabel',compose('%d',round(yticks/(365/da))));
colormap(jetwhite);
colorbar;
title('$\tilde{D}_H$ final distributions');

%% plotting the quantity of interest
figure_setups; hold on
t = (0:dt:tfinal)';
plot(t/365,Q_vals);
plot(t/365,Q_baseline,'r','MarkerSize',20);
xlabel('time (years)')
ylabel(lQ)
title (['vary ', lP])
legendStrings = lP + " = " + string(P_vals);
legend(legendStrings)