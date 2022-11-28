clearvars
% close all
clc

global P

% s =  load('Penny_ve_Siaya.mat','Data001'); Data = s.Data001; % point data
s =  load('Penny_ve_Siaya_model.mat','Penny_ve_Siaya_model'); Data = s.Penny_ve_Siaya_model; % curve data

Data(1,1) = 0;

%% numerical config
age_max = 100*365; % max ages in days
P.age_max = age_max;
dt = 10; % time/age step size in days, default = 5;
da = dt;
a = (0:da:age_max)';
na = length(a);

P.dt = dt; 
P.a = a;
P.na = na;
P.da = da;

Malaria_parameters_baseline;
Malaria_parameters_transform; 
P.v0s = 0; P.v0c = 0;
Malaria_parameters_transform_vac;

%% initial condition
[SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0] = age_structured_Malaria_IC_vac('EE');

lb = [0.1, 1/(5*365)]; % P.etas; P.w
ub = [1, 1/(0.1*365)];
x0 = [P.etas, P.w];

options = optimset('Display','iter','TolX',10^-5,'MaxIter',50);
[x,fval] = fmincon(@(x) fun_efficacy(x,Data,SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0),x0,[],[], [], [], lb, ub, [], options);

figure_setups; hold on
[~, xdata,ydata,yrun0] = fun_efficacy(x0,Data,SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0);
[~, ~,~,yrun1] = fun_efficacy(x,Data,SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0);
scatter(xdata,ydata,'filled')
plot(xdata,yrun0,xdata,yrun1)
legend('data - Penny','fitting - initial','fitting - final')
axis([0 1550 -0.3 0.8])
title('Fit to point data of efficacy')

% figure_setups; hold on
% [~, xdata,ydata,yrun0] = fun_efficacy(x0,Data,SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0);
% [~, ~,~,yrun1] = fun_efficacy(x,Data,SH0, EH0, DH0, AH0, VH0, UH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0);
% scatter(xdata,ydata,'filled')
% plot(xdata,yrun0,xdata,yrun1)
% legend('data - Penny','fitting - initial','fitting - final')
% axis([0 1550 -0.3 0.8])
% title('Fit to prediction curve, $\eta=1, w=1/(0.184*365)$')

