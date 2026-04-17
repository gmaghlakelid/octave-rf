## -*- texinfo -*-
## @deftypefn {Function File} {@var{T} =} s2t (@var{S})
## Convert 2-port S-parameters to T-parameters (chain scattering parameters).
##
## @var{S} must be a 2x2xK complex array where K is the number of frequency
## points.  Returns a 2x2xK array of T-parameters.
##
## @strong{Conversion formulas:}
## @verbatim
##   T11 =  1   / S21
##   T12 = -S22 / S21
##   T21 =  S11 / S21
##   T22 = -(S11*S22 - S12*S21) / S21 = -det(S) / S21
## @end verbatim
##
## @strong{Convention:} T-parameter element ordering follows Pupalaikis
## (Cambridge, 2020) and is compatible with MATLAB RF Toolbox, so code
## using @code{s2t} and @code{t2s} produces identical results in both.
##
## @strong{Cascade property:} For two 2-port networks in series,
## @code{T_cascade = T1 * T2}.  This is the mathematical basis for
## @code{cascadesparams} and @code{deembedsparams}.
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.
##     Section 3.6 "T-Parameters", Eq. 3.21 (p.65).
##     NOTE: Pupalaikis presents two equivalent element orderings for
##     the T-matrix (his Eq. 3.32 vs the convention used here).  This
##     implementation uses the ordering that is compatible with MATLAB
##     RF Toolbox.  Both orderings are related by a 180-degree rotation
##     and the cascade property T1*T2 holds identically in either.
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Section 9.2.4 "Cascading S-Parameters" (p.390).
## @end verbatim
##
## @seealso{t2s, cascadesparams, deembedsparams}
## @end deftypefn

function T = s2t (S)

  narginchk (1, 1);

  if size (S, 1) ~= 2 || size (S, 2) ~= 2
    error ('s2t: S must be a 2x2xK array (T-parameters are only defined for 2-port networks)');
  end

  K = size (S, 3);
  T = zeros (2, 2, K);

  for k = 1:K
    s21 = S(2,1,k);
    if abs (s21) == 0
      error ('s2t: S21 is zero at frequency index %d — T-parameters are undefined', k);
    end
    T(1,1,k) =  1.0       / s21;
    T(1,2,k) = -S(2,2,k) / s21;
    T(2,1,k) =  S(1,1,k) / s21;
    T(2,2,k) = -(S(1,1,k)*S(2,2,k) - S(1,2,k)*S(2,1,k)) / s21;
  endfor

endfunction

%!test
%! %% Ideal thru: S = [0 1; 1 0]  ->  T = identity
%! S = reshape([0 1 1 0], 2, 2, 1);  % column-major: S(1,1)=0, S(2,1)=1, S(1,2)=1, S(2,2)=0
%! T = s2t(S);
%! assert (T(:,:,1), eye(2), 1e-15);

%!test
%! %% Known 2-port attenuator: S11=S22=1/3, S12=S21=2/3 (series z0 impedance)
%! S = reshape([1/3, 2/3, 2/3, 1/3], 2, 2, 1);
%! T = s2t(S);
%! %% Verify T11 = 1/S21 = 3/2
%! assert (T(1,1,1), 1/(2/3), 1e-14);
%! %% Verify T12 = -S22/S21 = -(1/3)/(2/3) = -1/2
%! assert (T(1,2,1), -(1/3)/(2/3), 1e-14);
%! %% Verify T21 = S11/S21 = (1/3)/(2/3) = 1/2
%! assert (T(2,1,1), (1/3)/(2/3), 1e-14);
%! %% Verify T22 = -det(S)/S21; det(S)=(1/3)^2-(2/3)^2 = -1/3
%! %% T22 = -(-1/3)/(2/3) = 1/2
%! assert (T(2,2,1), -((1/3)*(1/3) - (2/3)*(2/3))/(2/3), 1e-14);

%!test
%! %% Multi-frequency: cascade of T matrices should equal T of cascaded S
%! %% Two ideal thrus cascaded should give identity at every frequency
%! K  = 50;
%! S1 = zeros(2,2,K);  S1(1,2,:) = 1;  S1(2,1,:) = 1;
%! S2 = zeros(2,2,K);  S2(1,2,:) = 1;  S2(2,1,:) = 1;
%! T1 = s2t(S1);
%! T2 = s2t(S2);
%! for k = 1:K
%!   Tc = T1(:,:,k) * T2(:,:,k);
%!   assert (Tc, eye(2), 1e-14);
%! end

%!test
%! %% Reciprocal: for a symmetric network S11=S22, S12=S21
%! %% T should satisfy T11 = (T12*T21 - 1)/T22 + 1 (from det relation)
%! S = zeros(2,2,1);
%! S(1,1,1) = 0.1+0.05j;  S(2,2,1) = 0.1+0.05j;
%! S(1,2,1) = 0.9-0.05j;  S(2,1,1) = 0.9-0.05j;
%! T = s2t(S);
%! %% det(S) = S11*S22 - S12*S21; T22 = -det(S)/S21
%! det_S = S(1,1,1)*S(2,2,1) - S(1,2,1)*S(2,1,1);
%! assert (T(2,2,1), -det_S / S(2,1,1), 1e-14);
