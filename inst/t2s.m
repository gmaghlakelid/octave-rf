## -*- texinfo -*-
## @deftypefn {Function File} {@var{S} =} t2s (@var{T})
## Convert 2-port T-parameters (chain scattering parameters) to S-parameters.
##
## @var{T} must be a 2x2xK complex array.  Returns a 2x2xK S-parameter array.
## This is the inverse of @code{s2t}.
##
## @strong{Conversion formulas:}
## @verbatim
##   S11 =  T21 / T11
##   S12 =  (T11*T22 - T12*T21) / T11   =  det(T) / T11
##   S21 =  1   / T11
##   S22 = -T12 / T11
## @end verbatim
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.
##     Section 3.6 "T-Parameters", Eq. 3.21 (p.65).
##     Uses the element ordering compatible with MATLAB RF Toolbox
##     (see s2t.m for the convention note).
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Section 9.2.4 "Cascading S-Parameters" (p.390).
## @end verbatim
##
## @seealso{s2t, cascadesparams, deembedsparams}
## @end deftypefn

function S = t2s (T)

  narginchk (1, 1);

  if size (T, 1) ~= 2 || size (T, 2) ~= 2
    error ('t2s: T must be a 2x2xK array');
  end

  K = size (T, 3);
  S = zeros (2, 2, K);

  for k = 1:K
    t11 = T(1,1,k);
    if t11 == 0
      error ('t2s: T11 is zero at frequency index %d — S-parameters are undefined', k);
    end
    S(1,1,k) =  T(2,1,k) / t11;
    S(1,2,k) = (T(1,1,k)*T(2,2,k) - T(1,2,k)*T(2,1,k)) / t11;
    S(2,1,k) =  1.0       / t11;
    S(2,2,k) = -T(1,2,k) / t11;
  endfor

endfunction

%!test
%! %% Round-trip: t2s(s2t(S)) == S for any S with S21 != 0
%! K  = 30;
%! S  = 0.1*rand(2,2,K) + 0.1j*rand(2,2,K);
%! S(2,1,:) += 0.8;   % ensure S21 is not near zero
%! S(1,2,:) = S(2,1,:);  % reciprocal
%! assert (t2s(s2t(S)), S, 1e-12);

%!test
%! %% Identity T-matrix -> thru S-parameters
%! T = repmat(eye(2), [1 1 5]);
%! S = t2s(T);
%! for k = 1:5
%!   assert (S(:,:,k), [0 1; 1 0], 1e-15);
%! end

%!test
%! %% S21 = 1/T11 identity
%! T = zeros(2,2,1);
%! T(1,1,1) = 1.5;  T(1,2,1) = -0.3;
%! T(2,1,1) = 0.3;  T(2,2,1) = 0.5;
%! S = t2s(T);
%! assert (S(2,1,1), 1/T(1,1,1), 1e-15);
%! assert (S(1,1,1), T(2,1,1)/T(1,1,1), 1e-15);
%! assert (S(2,2,1), -T(1,2,1)/T(1,1,1), 1e-15);

%!test
%! %% det(T) = S12 * T22 identity
%! S = zeros(2,2,1);
%! S(1,1,1) = 0.2;  S(2,2,1) = 0.15;
%! S(1,2,1) = 0.85; S(2,1,1) = 0.85;
%! T = s2t(S);
%! S2 = t2s(T);
%! assert (S2, S, 1e-14);
