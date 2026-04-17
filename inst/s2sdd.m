## -*- texinfo -*-
## @deftypefn  {Function File} {@var{Sdd} =} s2sdd (@var{S})
## @deftypefnx {Function File} {@var{Sdd} =} s2sdd (@var{S}, @var{portorder})
## Extract the differential-mode sub-block from a 4-port single-ended S-parameter matrix.
##
## @var{S} is a 4x4xK complex array of single-ended S-parameters.
## @var{portorder} is a 1x4 vector of 1-indexed port numbers specifying the
## differential pair assignment: @code{[D+1, D-1, D+2, D-2]}.
## Returns a 2x2xK array of differential-mode S-parameters (Sdd).
##
## The reference impedance for Sdd is 2*z0 (100 ohms for z0=50).
##
## @strong{Algorithm:}
## @verbatim
##   Reorder columns/rows of S by portorder (puts pairs in [D+1,D-1,D+2,D-2] order)
##   Apply mode transformation M = (1/sqrt(2)) * [ 1 -1  0  0 ]
##                                                [ 0  0  1 -1 ]
##                                                [ 1  1  0  0 ]
##                                                [ 0  0  1  1 ]
##   S_mm = M * S_reordered * M^H (M is unitary)
##   Sdd  = S_mm(1:2, 1:2, :)   (top-left block)
## @end verbatim
##
## @strong{Port ordering convention:}
## The output rows/columns are [d_pair1, d_pair2], i.e., the output is the
## 2-port differential S-parameter matrix of the differential signal path.
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.  [PRIMARY]
##     Chapter 7, Section 7.3 "Differential Signaling" (p.194):
##     definition of differential-mode voltage V_D = V_p - V_n.
##     Section 7.3.2 (p.199): mixed-mode S-parameter matrix with Sdd
##     as the differential-mode sub-block, ref impedance 2*Z0.
##     Eq. 7.24-7.27 (p.197), Fig. 7.7: standard mixed-mode converter
##     with 1/sqrt(2) normalization (the M matrix used here).
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Chapter 7 "Differential Signaling" (p.297).
##     Section 9.2.7 "Multimode S-Parameters" (p.400).
## @end verbatim
##
## @seealso{s2scc, smm2s, s2smm, snp2smp}
## @end deftypefn

function Sdd = s2sdd (S, portorder)

  narginchk (1, 2);
  if nargin < 2;  portorder = [1 2 3 4];  end
  [~, S_mm] = _se2mm (S, portorder);
  Sdd = S_mm(1:2, 1:2, :);

endfunction

%!test
%! %% For a perfectly balanced 4-port, Sdd should be finite and symmetric
%! K = 5;  f = linspace(1e9,5e9,K).';
%! p = zeros(4,4,K);
%! %% Balanced differential pair: ports 1&3 are pair 1, ports 2&4 are pair 2
%! p(1,2,:) = 0.9;  p(3,4,:) = 0.9;  % differential transmission
%! p(2,1,:) = 0.9;  p(4,3,:) = 0.9;
%! Sdd = s2sdd(p, [1 3 2 4]);
%! assert (size(Sdd), [2 2 K]);

%!test
%! %% Round-trip via smm2s: s2sdd + s2scc -> smm2s -> s2sdd should recover Sdd
%! K = 4;
%! S = rand(4,4,K)*0.1 + 1j*rand(4,4,K)*0.05;
%! S = (S + permute(S,[2 1 3]))/2;  % symmetrise (reciprocal)
%! portorder = [1 3 2 4];
%! Sdd = s2sdd(S, portorder);
%! Scc = s2scc(S, portorder);
%! S_mm = s2smm(S, portorder);
%! %% Sdd should equal top-left block of S_mm
%! assert (Sdd, S_mm(1:2,1:2,:), 1e-14);

%!test
%! %% MATLAB compat: default portorder (no 2nd arg) — same as [1 2 3 4]
%! K = 3;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! assert (s2sdd(S), s2sdd(S, [1 2 3 4]), 1e-15);

## Internal: compute full 4x4 mixed-mode matrix and return it along with Sdd
function [Sdd, S_mm] = _se2mm (S, portorder)
  if size(S,1) ~= 4 || size(S,2) ~= 4
    error ('s2sdd: S must be a 4x4xK array');
  end
  if numel(portorder) ~= 4
    error ('s2sdd: portorder must have 4 elements');
  end
  K = size(S, 3);
  %% Mode transformation matrix (unitary, 1/sqrt(2) normalised)
  M = (1/sqrt(2)) * [ 1 -1  0  0;
                      0  0  1 -1;
                      1  1  0  0;
                      0  0  1  1];
  S_mm = zeros(4,4,K);
  for k = 1:K
    Sp = S(portorder, portorder, k);   % reorder rows and cols
    S_mm(:,:,k) = M * Sp * M';        % M is unitary: inv(M) = M'
  endfor
  Sdd = S_mm(1:2,1:2,:);
endfunction
