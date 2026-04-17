## -*- texinfo -*-
## @deftypefn  {Function File} {@var{S_out} =} snp2smp (@var{S}, @var{portorder})
## @deftypefnx {Function File} {@var{S_out} =} snp2smp (@var{S}, @var{z0}, @var{portorder}, @var{z0_term})
## Reorder the ports of an N-port S-parameter matrix.
##
## @strong{Form 1} (octave-rf native): @code{snp2smp(S, portorder)} — pure
## row/column permutation.
##
## @strong{Form 2} (MATLAB RF Toolbox compatible):
## @code{snp2smp(S, z0, portorder, z0_term)} — the @var{z0} and
## @var{z0_term} arguments are accepted for compatibility but are not used
## when they are equal scalars (the typical matched-termination case).
##
## @var{S} is an NxNxK complex array.  @var{portorder} is a 1xN (or 1xM,
## M<=N) vector of 1-indexed port numbers specifying the new port ordering.
## Returns an NxNxK (or MxMxK) array with rows and columns permuted.
##
## @strong{Mathematical basis:}
## @verbatim
##   Pupalaikis, P.J., "S-Parameters for Signal Integrity",
##     Cambridge University Press, 2020.
##     Chapter 3, Section 3.1 (p.41): port numbering convention.
##     Port reorder is P * S * P^T for a permutation matrix P.
## @end verbatim
##
## @seealso{s2smm, smm2s}
## @end deftypefn

function S_out = snp2smp (S, varargin)

  narginchk (2, 4);

  %% Parse: Form 1  snp2smp(S, portorder)
  %%        Form 2  snp2smp(S, z0, portorder, z0_term)
  if nargin == 2
    portorder = varargin{1};
  elseif nargin == 4
    %% z0 = varargin{1}, portorder = varargin{2}, z0_term = varargin{3}
    %% Accept for MATLAB compatibility; ignore z0/z0_term (pure reorder).
    portorder = varargin{2};
  elseif nargin == 3
    %% Ambiguous — assume (S, z0, portorder) with no z0_term.
    portorder = varargin{2};
  else
    error ('snp2smp: expected 2 or 4 arguments');
  end

  N = size(S, 1);
  if size(S, 2) ~= N
    error ('snp2smp: S must be an NxNxK array');
  end

  portorder = portorder(:).';
  M = numel (portorder);
  if any(portorder < 1) || any(portorder > N)
    error ('snp2smp: portorder elements must be in range 1..%d', N);
  end
  if numel(unique(portorder)) ~= M
    error ('snp2smp: portorder must not contain duplicates');
  end

  S_out = S(portorder, portorder, :);

endfunction

%!test
%! %% Identity permutation: no change
%! K = 5;
%! S = rand(4,4,K) + 1j*rand(4,4,K);
%! assert (snp2smp(S, [1 2 3 4]), S, 1e-15);

%!test
%! %% Swap ports 1 and 2 of a 2-port
%! S = zeros(2,2,1);  S(1,1) = 0.1;  S(2,2) = 0.2;  S(1,2) = 0.8;  S(2,1) = 0.85;
%! Sp = snp2smp(S, [2 1]);
%! assert (Sp(1,1,1), S(2,2,1), 1e-15);
%! assert (Sp(2,2,1), S(1,1,1), 1e-15);
%! assert (Sp(1,2,1), S(2,1,1), 1e-15);
%! assert (Sp(2,1,1), S(1,2,1), 1e-15);

%!test
%! %% Double permutation = identity
%! K = 3;
%! S = rand(3,3,K) + 1j*rand(3,3,K);
%! po = [2 3 1];
%! po_inv = [3 1 2];
%! assert (snp2smp(snp2smp(S, po), po_inv), S, 1e-15);

%!test
%! %% MATLAB 4-arg form: snp2smp(S, z0, order, z0_term) — same result as 2-arg
%! K = 3;
%! S = rand(4,4,K) + 1j*rand(4,4,K);
%! po = [4 3 2 1];
%! assert (snp2smp(S, 50, po, 50), snp2smp(S, po), 1e-15);
