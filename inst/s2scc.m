## -*- texinfo -*-
## @deftypefn  {Function File} {@var{Scc} =} s2scc (@var{S})
## @deftypefnx {Function File} {@var{Scc} =} s2scc (@var{S}, @var{portorder})
## Extract the common-mode sub-block from a 4-port single-ended S-parameter matrix.
##
## @var{S} is a 4x4xK complex array.  @var{portorder} is @code{[D+1, D-1, D+2, D-2]}
## (1-indexed).  Returns a 2x2xK array of common-mode S-parameters (Scc).
## The reference impedance for Scc is z0/2 (25 ohms for z0=50).
##
## Scc is the bottom-right 2x2 block of the full mixed-mode matrix.
## See @code{s2sdd} for the mode transformation algorithm.
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.  [PRIMARY]
##     Chapter 7, Section 7.3 "Differential Signaling" (p.194):
##     common-mode voltage V_C = (V_p + V_n)/sqrt(2) for the standard
##     mixed-mode converter, Eq. 7.25 (p.197).
##     Section 7.3.2 (p.199): Scc is the common-mode sub-block of the
##     mixed-mode matrix, with reference impedance Z0/2.
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Chapter 7 "Differential Signaling" (p.297).
##     Section 9.2.7 "Multimode S-Parameters" (p.400).
## @end verbatim
##
## @seealso{s2sdd, smm2s, s2smm}
## @end deftypefn

function Scc = s2scc (S, portorder)

  narginchk (1, 2);
  if nargin < 2;  portorder = [1 2 3 4];  end
  S_mm = _mm (S, portorder);
  Scc = S_mm(3:4, 3:4, :);

endfunction

%!test
%! %% Output is 2x2xK
%! K = 5;
%! S = rand(4,4,K)*0.1;
%! Scc = s2scc(S, [1 3 2 4]);
%! assert (size(Scc), [2 2 K]);

%!test
%! %% Round-trip: bottom-right block of s2smm matches s2scc
%! K = 4;
%! S = rand(4,4,K)*0.1 + 1j*rand(4,4,K)*0.05;
%! S = (S + permute(S,[2 1 3]))/2;
%! portorder = [1 3 2 4];
%! Scc      = s2scc(S, portorder);
%! S_mm     = s2smm(S, portorder);
%! assert (Scc, S_mm(3:4,3:4,:), 1e-14);

%!test
%! %% MATLAB compat: default portorder (no 2nd arg) — same as [1 2 3 4]
%! K = 3;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! assert (s2scc(S), s2scc(S, [1 2 3 4]), 1e-15);

function S_mm = _mm (S, portorder)
  if size(S,1) ~= 4 || size(S,2) ~= 4
    error ('s2scc: S must be a 4x4xK array');
  end
  K = size(S,3);
  M = (1/sqrt(2)) * [ 1 -1  0  0;
                      0  0  1 -1;
                      1  1  0  0;
                      0  0  1  1];
  S_mm = zeros(4,4,K);
  for k = 1:K
    Sp = S(portorder, portorder, k);
    S_mm(:,:,k) = M * Sp * M';
  endfor
endfunction
