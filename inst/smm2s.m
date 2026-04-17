## -*- texinfo -*-
## @deftypefn {Function File} {@var{S} =} smm2s (@var{Sdd}, @var{Sdc}, @var{Scd}, @var{Scc}, @var{portorder})
## Convert mixed-mode sub-matrices back to a 4-port single-ended S-parameter matrix.
##
## Inputs are 2x2xK arrays:
## @itemize
## @item @var{Sdd} — differential-differential block
## @item @var{Sdc} — differential-to-common-mode coupling
## @item @var{Scd} — common-to-differential-mode coupling
## @item @var{Scc} — common-common block
## @end itemize
## @var{portorder} is @code{[D+1,D-1,D+2,D-2]} (1-indexed, same as in @code{s2smm}).
##
## Returns a 4x4xK single-ended S-parameter array.
## This is the inverse of @code{s2smm}.
##
## @strong{Algorithm:}
## @verbatim
##   Assemble S_mm = [Sdd Sdc; Scd Scc]
##   S_reordered   = M^H * S_mm * M   (M is unitary: M^H = inv(M))
##   S             = inverse port reordering (undo portorder permutation)
## @end verbatim
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.  [PRIMARY]
##     Chapter 7, Section 7.3.2 "Mixed-Mode S-Parameters" (p.199).
##     Eq. 7.24-7.27 (p.197): standard mixed-mode converter with
##     1/sqrt(2) normalization.  M is unitary (M^H = inv(M)), so the
##     inverse transform is S_reordered = M^H * S_mm * M.
##     Fig. 7.8(b) (p.198): mixed-mode to single-ended block diagram.
##
##   Hall, S.H. and Heck, H.L., "Advanced Signal Integrity for High-Speed
##     Digital Designs", Wiley-IEEE Press, 2009.
##     Chapter 7 (p.297); Section 9.2.7 "Multimode S-Parameters" (p.400).
## @end verbatim
##
## @seealso{s2smm, s2sdd, s2scc}
## @end deftypefn

function S = smm2s (Sdd, Sdc, Scd, Scc, portorder)

  narginchk (4, 5);
  if nargin < 5;  portorder = [1 2 3 4];  end

  K = size(Sdd, 3);
  if size(Sdc,3) ~= K || size(Scd,3) ~= K || size(Scc,3) ~= K
    error ('smm2s: all input blocks must have the same K (number of frequency points)');
  end
  if numel(portorder) ~= 4
    error ('smm2s: portorder must have 4 elements');
  end

  M = (1/sqrt(2)) * [ 1 -1  0  0;
                      0  0  1 -1;
                      1  1  0  0;
                      0  0  1  1];
  %% inv(M) = M' for unitary M
  Minv = M';

  %% Inverse portorder permutation: where does each port in [1..4] go?
  inv_po = zeros(1, 4);
  for i = 1:4
    inv_po(portorder(i)) = i;
  endfor

  S = zeros(4, 4, K);
  for k = 1:K
    %% Assemble full mixed-mode matrix
    S_mm = [Sdd(:,:,k), Sdc(:,:,k);
            Scd(:,:,k), Scc(:,:,k)];
    %% Undo mode transformation: S_reordered = M^H * S_mm * M
    Sp = Minv * S_mm * M;
    %% Undo port reordering
    S(:,:,k) = Sp(inv_po, inv_po);
  endfor

endfunction

%!test
%! %% Round-trip: smm2s(s2smm blocks) == original S
%! K = 5;
%! S = rand(4,4,K)*0.1 + 1j*rand(4,4,K)*0.05;
%! S = (S + permute(S,[2 1 3]))/2;
%! portorder = [1 3 2 4];
%! S_mm = s2smm(S, portorder);
%! Sdd = S_mm(1:2,1:2,:);  Sdc = S_mm(1:2,3:4,:);
%! Scd = S_mm(3:4,1:2,:);  Scc = S_mm(3:4,3:4,:);
%! S_rt = smm2s(Sdd, Sdc, Scd, Scc, portorder);
%! assert (S_rt, S, 1e-13);

%!test
%! %% Zero cross-coupling: smm2s(Sdd, 0, 0, Scc) recovers a balanced network
%! K = 3;
%! S = rand(4,4,K)*0.05;  S = (S+permute(S,[2 1 3]))/2;
%! portorder = [1 3 2 4];
%! Sdd = s2sdd(S, portorder);
%! Scc = s2scc(S, portorder);
%! %% With zero cross-terms, the result is NOT the original S but a balanced version
%! Sz  = zeros(2,2,K);
%! S_balanced = smm2s(Sdd, Sz, Sz, Scc, portorder);
%! %% Verify: s2sdd of the result equals Sdd
%! assert (s2sdd(S_balanced, portorder), Sdd, 1e-13);
%! assert (s2scc(S_balanced, portorder), Scc, 1e-13);

%!test
%! %% MATLAB compat: default portorder (no 5th arg) — same as [1 2 3 4]
%! K = 3;
%! S = rand(4,4,K)*0.1;  S = (S+permute(S,[2 1 3]))/2;
%! [Sdd, Sdc, Scd, Scc] = s2smm(S);
%! S_with_po = smm2s(Sdd, Sdc, Scd, Scc, [1 2 3 4]);
%! S_default = smm2s(Sdd, Sdc, Scd, Scc);
%! assert (S_default, S_with_po, 1e-15);
