function [ Isn, IP3H, IDG3 ] = SimTrace(Mx, My, photon_en, FEE_Slit_x, FEE_Slit_y, LHOMS, X0, X0P, Y0P, M1H_X, M1H_Z, M1H_A, P2H_X, P2H_Z, M2H_X, M2H_Z, M2H_A, P3H_X, P3H_Z, DG3_X, DG3_Z)
%SIMTRACE Run Jacik's sim without the gui
%   Wrap SimTraceProp inside of a function block


%M1H_Z=90.510;
%M2H_Z=101.843;
%P2H_Z=100.828;
%P3H_Z= 103.660;
%DG3_Z=375.000;



alpha=0.0014;
alpha1=pi/2-alpha;
zSource=0;


if abs(X0P)<=(FEE_Slit_x/2-X0)/(73.8230+zSource);
phiX0P=pi/2+X0P;
elseif X0P > (FEE_Slit_x/2-X0)/(73.8230+zSource);
phiX0P =pi/2+ (FEE_Slit_x/2-X0)/(73.8230+zSource);
else X0P < -(FEE_Slit_x/2-X0)/(73.8230+zSource);
    phiX0P=pi/2-(FEE_Slit_x/2-X0)/(73.8230+zSource);
end
    
% phiX0P=pi/2+X0P
nrx=sin(phiX0P); nrz=cos(phiX0P);
xr=X0; zr=zSource;

phiM1H_X=alpha1-M1H_A;

nmx=sin(phiM1H_X); nmz=cos(phiM1H_X);

xm=M1H_X; zm=M1H_Z;

nsx=0; nsz=1; xs=P2H_X; zs=P2H_Z;

[ xi,zi,vrefl,xis,zis ] = JacRaytrace( nrx,nrz,xr,zr,nmx,nmz,xm,zm,nsx,nsz,xs,zs);

alpha2=pi/2-alpha;

phiM2H_X=alpha2+M2H_A;
xm2=(M2H_Z-M1H_Z)*sin(0.0028)+M2H_X;
zm2=M2H_Z;
ns2x=0; ns2z=1; xs2=P3H_X; zs2=P3H_Z;

nm2x=sin(phiM2H_X); nm2z=cos(phiM2H_X);

ns3x=0; ns3z=1; xs3=DG3_X; zs3=DG3_Z;


% [ xi,zi,vrefl ] = JacSec( nrx,nrz,xr,zr,nmx,nmz,xm,zm)


[ xi2,zi2,vref2,xis2,zis2 ] = JacRaytrace( vrefl(1),vrefl(2),xi,zi,nm2x,nm2z,xm2,zm2,ns2x,ns2z,xs2,zs2);

[ xi2,zi2,vref2,xis3,zis3 ] = JacRaytrace( vrefl(1),vrefl(2),xi,zi,nm2x,nm2z,xm2,zm2,ns3x,ns3z,xs3,zs3);

delxis=xis-0.0289+9.5245e-06;
delxis2=xis2-0.0317-3.2234e-05;
delxis3=xis3-0.0317-3.2234e-05;

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

lambda=1.24/photon_en*1E-6; % X-ray wavelegth [m]
conversion_from_SI_units=2*pi/lambda; %conversion to new units from SI units
%conv=conversion_from_SI_units;



% [btf] = f_2D_free_prop_spectr_jac(dx,dy,L(ff)*conv,Efield);

%######################################################################
% [out_wf,x_out_f,y_out_f] = f_2D_prop_fresnel(dx,dy,L(ff)*conv,Efield);




conversion_from_SI_units=2*pi/lambda; %conversion to new units from SI units
convr=conversion_from_SI_units;


divrms=1.5e-6*(8300/photon_en)^.8;
om0= 1/divrms;
zR =(om0^2)/2;    %Rayleigh parameter in the internal units (lamda =2*pi)
%zX = 0; %distance of the source w/r to the undulator exi






%=============================================
% Define Propagation Parameters
%=============================================

% size of the space window 0.004 x 0.004 [m]
 Xrange = 0.010*conversion_from_SI_units;
 Yrange = 0.010*conversion_from_SI_units;
 %space steps
 dx = Xrange/(Mx-1) ; %x space step
 dy = Yrange/(My-1) ;  %y space step
 Tx = round((Mx+1)/2);
 Ty =round((My+1)/2); %coordinates of the center of the matrix
x = dx*((1:Mx)-Tx); y = dy*((1:My)-Ty); 

[Yj,Xj] = meshgrid(y,x);
r_sqr=Xj.^2+Yj.^2;
% x_sqr=Xj.^2;
% y_sqr=Yj.^2;
% rsqr0=r_sqr(Tx,Ty);
 



%=============================================
%  Gaussian field.
%=============================================




%================================================%
% Analitical propagation fom source to the slit
source_pos=0;
M1H_Z_Xp= (73.8230+source_pos)*convr; %distance undulator slit 
%================================================%
M1H_Z_X=M1H_Z_Xp;

E00=1;
   
E001= E00*1/(1+1i*M1H_Z_X/zR)*exp(-(((r_sqr./((om0.^2)*(1+1i*M1H_Z_X/zR)))))).*exp(1i*(X0P.*Xj+Y0P.*Yj)); 

% [E001,x,y] = f_2D_prop_fresnel(dx1,dy1,M1H_Z_X,Efield);


%===================================
%FEE_SITS
%=================================
log_FEESLITX=abs(Xj)<=FEE_Slit_x*convr/2;
log_FEESLITY=abs(Yj)<=FEE_Slit_y*convr/2;



%================================================%
% aperturing by the FEEslit
%================================================%


E02=E001.*log_FEESLITX.*log_FEESLITY;
%================================================%
% Numerical  propagation from the slit to GA by 5.1 m
S_GA=5.1*convr;
%================================================%

  [ESGA] = f_2D_free_prop_spectr_jac_shift(dx,dy,S_GA,E02);

log_GA=(Xj-0*convr).^2+(Yj-0*convr).^2<=(40e-3/2*convr).^2;
 ESGA_ap=ESGA.*log_GA;

%================================================%
% Numerical  propagation from the GA to MH1 by  11.5870+zi m
GA_MH1=(zi-5.1-73.8230)*convr;
%================================================%

  [EMS1] = f_2D_free_prop_spectr_jac_shift(dx,dy,GA_MH1,ESGA_ap);

  %================================================%
% aperturing by the MH1 aperture
%================================================%

log_MH1=(abs(Xj-M1H_X*convr))<=LHOMS*alpha*convr/2;



EMS1Ap=EMS1.*log_MH1.*exp(1i*(0.*Xj));
%================================================%
% Numerical  propagation from the  MH1 to MH2 
MH1_MH2=(zi2-zi)*convr;
%================================================%

 [EMS2] = f_2D_free_prop_spectr_jac_shift(dx,dy,MH1_MH2,EMS1Ap);

 
 nM1H_Xshift=round(delxis*convr/dx);
 Isn0=(abs(EMS2).^2);
 Isn=circshift(Isn0,[nM1H_Xshift]);

  %================================================%
% aperturing by the MH2 aperture
%================================================%
log_MH2=abs(Xj-M2H_X*convr)<=LHOMS*alpha*convr/2;

EMS2Ap=EMS2.*log_MH2.*exp(1i*vref2(2)*Xj);

%================================================%
% Numerical  propagation from the  MH2  by (103.6-101.843) m
MH2_P3H=(P3H_Z-zi2)*convr;
%================================================%

 [EMP3H] = f_2D_free_prop_spectr_jac_shift(dx,dy,MH2_P3H,EMS2Ap);
 
IP3H0=flipud(abs(EMP3H).^2);
nM1H_Xshift=round(delxis2*convr/dx);

 IP3H=circshift(IP3H0,[nM1H_Xshift]);
 
%================================================%
% Numerical  propagation from the  MH2 to DD3 by 200 m
MH2_DG3=(DG3_Z-zi2)*convr;
%================================================%
% zD1=M1H_Z_X+S_GA+GA_MS1+MS1_MS2+MS1_M1;
% Rd=zR^2/(zD1) +zD1;     %radius of curvature of incoming beam
% Rdm=Rd/convr;
 [EMDG3] = f_2D_free_prop_spectr_jac_shift(dx,dy,MH2_DG3,EMS2Ap);
%  Rdp=Rd;

 IDG30=flipud(abs(EMDG3).^2);

nM1H_Xshift=round(delxis3*convr/dx);

 IDG3=circshift( IDG30,[nM1H_Xshift]);
  %================================================%
% aperturing by the M1 aperture
%================================================%

% log_col1=r_sqr<=(3.5e-3/2*convr).^2;
% log_GY=Yj<=aptY*convr;
% log_GX=Xj<=aptY*convr;
% 
% 
% 
% phiX0Pd=phiX0P-pi/2
% 

end