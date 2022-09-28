function [SH, EH, DH, AH, SM, EM, IM, Cm, Cac, Cv, Ctot, MH,SHv, EHv, DHv, AHv] = ...
    age_structured_Malaria_eff_control(da, na, tfinal, SH0, EH0, DH0, AH0, SM0, EM0, IM0, Cm0, Cac0, Cv0, Ctot0, MH0,SHv0, EHv0, DHv0, AHv0)
global P

dt = da;
t = (0:dt:tfinal)';
nt = length(t);

% allocation
% SH, EH, etc.. = cell averages
SH = NaN(na,nt); EH = NaN(na,nt); DH = NaN(na,nt); AH = NaN(na,nt); MH = NaN(na,nt);
SM = NaN(1,nt); EM = NaN(1,nt); IM = NaN(1,nt);
Cm = NaN(na,nt); Cac = NaN(na,nt); Cv = NaN(na,nt); Ctot = NaN(na,nt);
NH = NaN(1,nt); NM = NaN(nt);

SH(:,1) = SH0; EH(:,1) = EH0; DH(:,1) = DH0; AH(:,1) = AH0; MH(:,1) = MH0; 
SM(1) = SM0; EM(1) = EM0; IM(1) = IM0;
Cm(:,1) = Cm0; Cac(:,1) = Cac0; Cv(:,1) = Cv0; Ctot(:,1) = Ctot0;
NH(1) = trapz(SH(:,1)+EH(:,1)+DH(:,1)+AH(:,1))*da;
NM(1) = SM(1)+EM(1)+IM(1);

% diagnostic for vaccinated cohort
SHv = NaN(na,nt); EHv = NaN(na,nt); DHv = NaN(na,nt); AHv = NaN(na,nt); 
SHv(:,1) = SHv0; EHv(:,1) = EHv0; DHv(:,1) = DHv0; AHv(:,1) = AHv0; 

% update progression probability based on immunity Ctot
PH0 = SH(:,1)+EH(:,1)+DH(:,1)+AH(:,1);
P.phi = sigmoid_prob(Ctot0./PH0, 'phi'); % prob. of DH -> RH
P.rho = sigmoid_prob(Ctot0./PH0, 'rho'); % prob. of severely infected, EH -> DH
P.psi = sigmoid_prob(Ctot0./PH0, 'psi'); % prob. AH -> DH
            
%% time evolution
for n = 1:nt-1
    PH = SH(:,n)+EH(:,n)+DH(:,n)+AH(:,n); % total human at age a, t = n
    NH(n) = trapz(PH)*da; % total human population at t=n;
    NM(n) = SM(1,n)+EM(1,n)+IM(1,n);
    [bH,~] = biting_rate(NH(n),NM(n));
    lamH = FOI_H(bH,IM(1,n),NM(n));  % force of infection at t=n
    
    % human birth terms
    SH(1,n+1) = trapz(P.gH.*PH)*da;
    EH(1,n+1) = 0;
    DH(1,n+1) = 0;
    AH(1,n+1) = 0;
    MH(1,n+1) = 0; % diagnostic, disease-induced mortality
    SHv(1,n+1) = 0;
    EHv(1,n+1) = 0;
    DHv(1,n+1) = 0;
    AHv(1,n+1) = 0;
    
    %% human time evolution
    SH(2:end,n+1) = (SH(1:end-1,n)+dt*(P.phi(1:end-1)*P.rD.*DH(1:end-1,n)+P.rA*AH(1:end-1,n)))...
        ./(1+(lamH+P.muH(2:end))*dt); 
    EH(2:end,n+1) = (EH(1:end-1,n)+dt*lamH*(SH(2:end,n+1)))...
        ./(1+(P.h+P.muH(2:end))*dt);
    temp2 = (1-P.rho(1:end-1))*P.h.*EH(2:end,n+1)+(1-P.phi(1:end-1)).*P.rD.*DH(1:end-1,n);
    AH(2:end,n+1) = ((1-dt*P.rA)*AH(1:end-1,n)+dt*temp2)...
        ./(1+dt*(P.psi(1:end-1)*lamH+P.muH(2:end)));
    temp3 = P.rho(1:end-1)*P.h.*EH(2:end,n+1)+P.psi(1:end-1).*lamH.*AH(2:end,n+1);
    DH(2:end,n+1) = ((1-dt*P.rD)*DH(1:end-1,n)+dt*temp3)...
        ./(1+dt*(P.muH(2:end)+P.muD(2:end)));
    %% diagnostic, disease-induced mortality counts
    MH(2:end,n+1) = MH(1:end-1,n)+dt*P.muD(2:end).*DH(2:end,n+1);
    %% vaccinated cohort
    SHv(2:end,n+1) = (SHv(1:end-1,n)+dt*(P.phi(1:end-1)*P.rD.*DHv(1:end-1,n)+P.rA*AHv(1:end-1,n)+P.v(2:end).*SH(2:end,n+1)))...
        ./(1+(lamH+P.muH(2:end))*dt);      
    EHv(2:end,n+1) = (EHv(1:end-1,n)+dt*lamH*(SHv(2:end,n+1)))...
        ./(1+(P.h+P.muH(2:end))*dt);
    temp2 = (1-P.rho(1:end-1))*P.h.*EHv(2:end,n+1)+(1-P.phi(1:end-1)).*P.rD.*DHv(1:end-1,n);
    AHv(2:end,n+1) = ((1-dt*P.rA)*AHv(1:end-1,n)+dt*temp2)...
        ./(1+dt*(P.psi(1:end-1)*lamH+P.muH(2:end)));
    temp3 = P.rho(1:end-1)*P.h.*EHv(2:end,n+1)+P.psi(1:end-1).*lamH.*AHv(2:end,n+1);
    DHv(2:end,n+1) = ((1-dt*P.rD)*DHv(1:end-1,n)+dt*temp3)...
        ./(1+dt*(P.muH(2:end)+P.muD(2:end)));
    %%
    PHp1 = SH(:,n+1)+EH(:,n+1)+DH(:,n+1)+AH(:,n+1); % total human at age a, t = n+1
    NHp1 = trapz(PHp1)*da; % total human population at t=n+1;
    % mosquito time evolution
    [SM(1,n+1),EM(1,n+1),IM(1,n+1)] = mosquito_ODE(SM(1,n), EM(1,n), IM(1,n), DH(:,n), AH(:,n), NH(n), NHp1, NM(n));
    NM(n+1) = SM(1,n+1)+EM(1,n+1)+IM(1,n+1);
    
    % immunity gained at age = 0 
    Cm(1,n+1) = P.m*trapz(P.gH.*(P.c1*Cac(:,n)+P.c3*Cv(:,n)))*da;
    Cac(1,n+1) = 0;
    Cv(1,n+1) = 0;
    % maternal immunity
    %n0 = min(n,na-1); % comment this formula for now, use implicit scheme
    %Cm(2:n0+1,n+1) = (Cm(1,1:n0))'.*exp(-a(2:n0+1)/P.dm); % k=1:n0
    %Cm(n0+2:end,n+1) = Cm(2:end-n0,1).*exp(-t(n+1)/P.dm);  % k=n0+1:end-1
    % acquired immunity - use Qn+1
    [bHp1,~] = biting_rate(NHp1,NM(n+1));
    lamHp1 = FOI_H(bHp1,IM(1,n+1),NM(n+1));
    % Cm and Cac are both pooled immunity
    Bnp1 = f(lamHp1).*(P.cS*SH(2:end,n+1) + P.cE*EH(2:end,n+1) + P.cA*AH(2:end,n+1) + P.cD*DH(2:end,n+1));
    Dnp1 = P.muH(2:end) + P.muD(2:end).*DH(2:end,n+1)./PHp1(2:end);
    Cac(2:end,n+1) = (Cac(1:end-1,n)+dt*Bnp1)./(1+dt*(1/P.dac+Dnp1));
    Cm(2:end,n+1) = Cm(1:end-1,n)./(1+dt*(1/P.dm+Dnp1));
    Cv(2:end,n+1) = Cv(1:end-1,n)./(1+dt*(1/P.dv+Dnp1));
    Ctot(:,n+1) = P.c1*Cac(:,n+1)+P.c2*Cm(:,n+1)+P.c3*Cv(:,n+1); % total immunity from acquired, maternal and vaccine-derived sources
    % update progression probability based on immunity Ctot
    P.phi = sigmoid_prob(Ctot(:,n+1)./PHp1, 'phi'); % prob. of DH -> RH
    P.rho = sigmoid_prob(Ctot(:,n+1)./PHp1, 'rho'); % prob. of severely infected, EH -> DH
    P.psi = sigmoid_prob(Ctot(:,n+1)./PHp1, 'psi'); % prob. AH -> DH
end

end
