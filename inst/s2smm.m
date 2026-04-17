## -*- texinfo -*-
## @deftypefn  {Function File} {@var{S_mm} =} s2smm (@var{S})
## @deftypefnx {Function File} {@var{S_mm} =} s2smm (@var{S}, @var{portorder})
## @deftypefnx {Function File} {[@var{Sdd}, @var{Sdc}, @var{Scd}, @var{Scc}] =} s2smm (@dots{})
## Convert a 4-port single-ended S-parameter matrix to the full mixed-mode matrix.
##
## @var{S} is a 4x4xK complex array.  @var{portorder} is @code{[D+1,D-1,D+2,D-2]}
## (1-indexed).  Returns a 4x4xK mixed-mode S-parameter matrix where the
## row/column ordering is @code{[d_pair1, d_pair2, c_pair1, c_pair2]}.
##
## The blocks are:
## @verbatim
##   S_mm = [ Sdd  Sdc ]   rows/cols: [d1,d2,c1,c2]
##          [ Scd  Scc ]
## @end verbatim
##
## @strong{Algorithm:}
## @verbatim
##   Reorder S by portorder (rows and cols)
##   S_mm = M * S_reordered * M^H
##   M = (1/sqrt(2)) * [ 1 -1  0  0 ]   <- differential pair 1
##                     [ 0  0  1 -1 ]   <- differential pair 2
##                     [ 1  1  0  0 ]   <- common-mode pair 1
##                     [ 0  0  1  1 ]   <- common-mode pair 2
## @end verbatim
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.  [PRIMARY]
##     Chapter 7, Section 7.3 "Differential Signaling" (p.194).
##     Section 7.3.2 "Mixed-Mode S-Parameters" (p.199): 4-port
##     single-ended to mixed-mode conversion.
##     Eq. 7.24-7.27 (p.197), Fig. 7.7: "standard mixed-mode converter"
##     with 1/sqrt(2) normalization:
##       V_D = (V_p - V_n)/sqrt(2),  V_C = (V_p + V_n)/sqrt(2)
##     — this is the M matrix used here.
##     Fig. 7.8 (p.198): block diagram of the 4-port <-> mixed-mode
##     conversion (mirrors this implementation's reorder + M*S*M^H).
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Chapter 7 "Differential Signaling" (p.297) — SI-engineering
##     perspective on mode conversion and differential crosstalk.
##     Section 9.2.7 "Multimode S-Parameters" (p.400) — full
##     mixed-mode matrix derivation from single-ended 4-port.
## @end verbatim
##
## @seealso{smm2s, s2sdd, s2scc}
## @end deftypefn

function [out1, out2, out3, out4] = s2smm (S, portorder)

  narginchk (1, 2);
  if nargin < 2;  portorder = [1 2 3 4];  end

  if size(S,1) ~= 4 || size(S,2) ~= 4
    error ('s2smm: S must be a 4x4xK array');
  end
  if numel(portorder) ~= 4
    error ('s2smm: portorder must have 4 elements');
  end

  K = size(S, 3);
  M = (1/sqrt(2)) * [ 1 -1  0  0;
                      0  0  1 -1;
                      1  1  0  0;
                      0  0  1  1];
  S_full = zeros(4, 4, K);
  for k = 1:K
    Sp = S(portorder, portorder, k);
    S_full(:,:,k) = M * Sp * M';
  endfor

  %% Route outputs:  1 output  -> full 4x4xK mixed-mode matrix
  %%                  4 outputs -> [Sdd, Sdc, Scd, Scc] (MATLAB RF Toolbox style)
  if nargout <= 1
    out1 = S_full;
  else
    out1 = S_full(1:2, 1:2, :);   %% Sdd
    out2 = S_full(1:2, 3:4, :);   %% Sdc
    out3 = S_full(3:4, 1:2, :);   %% Scd
    out4 = S_full(3:4, 3:4, :);   %% Scc
  end

endfunction

%!test
%! %% Output is 4x4xK
%! K = 3;
%! S = rand(4,4,K)*0.1;
%! S_mm = s2smm(S, [1 3 2 4]);
%! assert (size(S_mm), [4 4 K]);

%!test
%! %% Round-trip: smm2s(s2smm(S)) == S
%! K = 5;
%! S = rand(4,4,K)*0.1 + 1j*rand(4,4,K)*0.05;
%! S = (S + permute(S,[2 1 3]))/2;
%! portorder = [1 3 2 4];
%! S_mm = s2smm(S, portorder);
%! Sdd = S_mm(1:2,1:2,:);
%! Sdc = S_mm(1:2,3:4,:);
%! Scd = S_mm(3:4,1:2,:);
%! Scc = S_mm(3:4,3:4,:);
%! S_rt = smm2s(Sdd, Sdc, Scd, Scc, portorder);
%! assert (S_rt, S, 1e-13);

%!test
%! %% Sdd block matches s2sdd output
%! K = 4;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! portorder = [1 3 2 4];
%! assert (s2smm(S,portorder)(1:2,1:2,:), s2sdd(S,portorder), 1e-14);
%! assert (s2smm(S,portorder)(3:4,3:4,:), s2scc(S,portorder), 1e-14);

%!test
%! %% MATLAB compat: default portorder (no 2nd arg) — same as [1 2 3 4]
%! K = 3;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! assert (s2smm(S), s2smm(S, [1 2 3 4]), 1e-15);

%!test
%! %% MATLAB compat: 4-output form [Sdd, Sdc, Scd, Scc]
%! K = 3;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! [Sdd, Sdc, Scd, Scc] = s2smm(S);
%! Smm = s2smm(S);
%! assert (Sdd, Smm(1:2,1:2,:), 1e-15);
%! assert (Sdc, Smm(1:2,3:4,:), 1e-15);
%! assert (Scd, Smm(3:4,1:2,:), 1e-15);
%! assert (Scc, Smm(3:4,3:4,:), 1e-15);
