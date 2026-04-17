## -*- texinfo -*-
## @deftypefn  {Function File} {@var{s} =} sparameters (@var{filename})
## @deftypefnx {Function File} {@var{s} =} sparameters (@var{params}, @var{freq})
## @deftypefnx {Function File} {@var{s} =} sparameters (@var{params}, @var{freq}, @var{z0})
## @deftypefnx {Function File} {@var{s} =} sparameters (@var{s_obj}, @var{z0_new})
## Create an S-parameter object (struct) from a Touchstone file, from raw
## arrays, or renormalize an existing one.
##
## @strong{Form 1} (MATLAB compatible): @code{sparameters(filename)} reads a
## Touchstone file (.s1p, .s2p, .s4p, etc.) and returns the S-parameter
## struct.  Uses the bundled @code{fromtouchn} reader.  Reference impedance
## is read from the Touchstone header (defaults to 50 ohms).
##
## @strong{Form 2}: @code{sparameters(params, freq)} creates an S-parameter
## object from a raw @var{N}x@var{N}x@var{K} parameter array and a @var{K}x1
## frequency vector.  Reference impedance defaults to 50 ohms.
##
## @strong{Form 3}: @code{sparameters(params, freq, z0)} creates an object
## with reference impedance @var{z0} (scalar, in ohms).  If @var{z0} != 50,
## the S-parameters are renormalized to a 50-ohm reference before storing.
##
## @strong{Form 4}: @code{sparameters(s_obj, z0_new)} renormalizes an
## existing S-parameter object to new reference impedance @var{z0_new}.
##
## The returned struct has four fields (matching MATLAB RF Toolbox):
## @itemize
## @item @code{Parameters} --- @var{N}x@var{N}x@var{K} complex array
## @item @code{Frequencies} --- @var{K}x1 column vector (Hz)
## @item @code{Impedance} --- reference impedance (scalar, ohms)
## @item @code{NumPorts} --- number of ports (integer)
## @end itemize
##
## @seealso{rfparam, cascadesparams, deembedsparams, embedsparams}
## @end deftypefn

function s = sparameters (varargin)

  narginchk (1, 3);

  if nargin == 1 && ischar (varargin{1})
    %% Form 1: sparameters(filename) — read Touchstone file (MATLAB compatible)
    filename = varargin{1};
    if ~exist (filename, 'file')
      error ('sparameters: file not found: %s', filename);
    end
    ws = warning ('off', 'all');   %% fromtouchn uses legacy syntax
    unwind_protect
      [freq, params, ~] = fromtouchn (filename);
    unwind_protect_cleanup
      warning (ws);
    end_unwind_protect
    if ndims (params) == 2
      params = reshape (params, size(params,1), size(params,2), 1);
    end
    s.Parameters  = params;
    s.Frequencies = freq(:);
    s.Impedance   = 50.0;
    s.NumPorts    = size (params, 1);

  elseif nargin == 2 && isstruct (varargin{1})
    %% Form 3: sparameters(s_obj, z0_new) — renormalize
    s_in   = varargin{1};
    z0_new = varargin{2};
    if ~isfield (s_in, 'Parameters') || ~isfield (s_in, 'Frequencies')
      error ('sparameters: first argument must be a sparameters struct with Parameters and Frequencies fields');
    end
    if ~isscalar (z0_new) || ~isreal (z0_new) || z0_new <= 0
      error ('sparameters: z0_new must be a positive real scalar');
    end
    %% Renormalize: assume stored params are referenced to 50 ohms
    z0_old = 50.0;
    P      = _renorm (s_in.Parameters, z0_old, z0_new);
    s.Parameters  = P;
    s.Frequencies = s_in.Frequencies(:);
    s.Impedance   = z0_new;
    s.NumPorts    = size (P, 1);

  elseif nargin == 2 && isnumeric (varargin{1})
    %% Form 1: sparameters(params, freq) — z0 = 50 assumed
    params = varargin{1};
    freq   = varargin{2};
    if ndims (params) < 2 || ndims (params) > 3
      error ('sparameters: params must be an NxN or NxNxK array');
    end
    if ndims (params) == 2
      params = reshape (params, size(params,1), size(params,2), 1);
    end
    s.Parameters  = params;
    s.Frequencies = freq(:);
    s.Impedance   = 50.0;
    s.NumPorts    = size (params, 1);

  elseif nargin == 3
    %% Form 2: sparameters(params, freq, z0) — store, renorm to 50 if needed
    params = varargin{1};
    freq   = varargin{2};
    z0     = varargin{3};
    if ndims (params) == 2
      params = reshape (params, size(params,1), size(params,2), 1);
    end
    if ~isscalar (z0) || ~isreal (z0) || z0 <= 0
      error ('sparameters: z0 must be a positive real scalar');
    end
    if z0 ~= 50.0
      params = _renorm (params, z0, 50.0);
    end
    s.Parameters  = params;
    s.Frequencies = freq(:);
    s.Impedance   = 50.0;
    s.NumPorts    = size (params, 1);

  else
    error ('sparameters: unrecognized argument combination');
  end

endfunction

%% Internal helper: renormalize S-parameters from z0_old to z0_new.
%% Mathematical basis:
%%   Step 1 — convert to Z:  Z = z0_old * (I+S) * inv(I-S)
%%   Step 2 — convert back:  S_new = (Z - z0_new*I) * inv(Z + z0_new*I)
%% Pupalaikis, P.J., "S-Parameters for Signal Integrity",
%%   Cambridge University Press, 2020.
%%   Chapter 5, Section 5.1 "Basic Reference Impedance Transformation"
%%   (p.134): renormalization via Z intermediate.
%%   Section 3.4.1 Table 3.2 (p.55) and 3.4.2 Table 3.3 (p.56) for the
%%   S<->Z conversions used above.
%% Pozar, D.M., "Microwave Engineering", 4th ed., Wiley, 2012.
%%   Section 4.3, Eq. 4.44-4.45 (p.181): S<->Z conversion.
function P_new = _renorm (P, z0_old, z0_new)
  [N, ~, K] = size (P);
  P_new = zeros (N, N, K);
  I = eye (N);
  for k = 1:K
    s = P(:,:,k);
    Z = z0_old * (I + s) / (I - s);
    P_new(:,:,k) = (Z - z0_new*I) / (Z + z0_new*I);
  endfor
endfunction

%!test
%! %% Form 1: basic constructor — check fields exist and dimensions are correct
%! f = [1e9; 2e9; 3e9];
%! p = zeros(2,2,3);  p(1,2,:) = 1;  p(2,1,:) = 1;  % ideal thru
%! s = sparameters(p, f);
%! assert (isstruct(s));
%! assert (isfield(s, 'Parameters'));
%! assert (isfield(s, 'Frequencies'));
%! assert (size(s.Parameters),  [2 2 3]);
%! assert (size(s.Frequencies), [3 1]);

%!test
%! %% Form 2: z0=50 — no renormalization, params stored unchanged
%! f = [1e9; 2e9];
%! p = zeros(2,2,2);  p(1,2,:) = 0.9;  p(2,1,:) = 0.9;  p(1,1,:) = 0.1;
%! s = sparameters(p, f, 50);
%! assert (s.Parameters, p, 1e-15);

%!test
%! %% Form 2: z0 != 50 — matched load at z0=100 becomes S11=1/3 when viewed from 50
%! %% A 1-port S11=0 at z0=100 corresponds to Z=100, which at z0=50 is S11=(100-50)/(100+50)=1/3
%! f = [1e9];
%! p = zeros(1,1,1);  % S11=0 at z0=100 (matched)
%! s = sparameters(p, f, 100);
%! assert (s.Parameters(1,1,1), 1/3, 1e-14);

%!test
%! %% Form 3: renormalization round-trip — z0=100 → z0=50 → z0=100 recovers original
%! f = [1e9; 2e9];
%! p_orig = zeros(2,2,2);
%! p_orig(1,1,:) = 0.2;  p_orig(2,2,:) = 0.1;
%! p_orig(1,2,:) = 0.8;  p_orig(2,1,:) = 0.8;
%! s50  = sparameters(p_orig, f, 100);   % 100-ohm → stored as 50-ohm
%! s100 = sparameters(s50, 100);          % 50-ohm → back to 100-ohm
%! assert (s100.Parameters, p_orig, 1e-12);

%!test
%! %% 2D params (single frequency) are automatically reshaped to NxNx1.
%! %% Note: Octave/MATLAB drop trailing singleton dimensions from ndims/size,
%! %% so use size(A, dim) to check individual dimensions.
%! f = 1e9;
%! p = [0 1; 1 0];
%! s = sparameters(p, f);
%! assert (size(s.Parameters, 1), 2);
%! assert (size(s.Parameters, 2), 2);
%! assert (size(s.Parameters, 3), 1);  %% K=1 dimension is preserved internally

%!test
%! %% MATLAB compat: .Impedance and .NumPorts fields exist
%! f = [1e9; 2e9; 3e9];
%! p = zeros(2,2,3);  p(1,2,:) = 1;  p(2,1,:) = 1;
%! s = sparameters(p, f);
%! assert (isfield(s, 'Impedance'));
%! assert (isfield(s, 'NumPorts'));
%! assert (s.Impedance, 50);
%! assert (s.NumPorts, 2);

%!test
%! %% MATLAB compat: .Impedance tracks renormalization (Form 3)
%! f = [1e9; 2e9];
%! p = zeros(2,2,2);  p(1,2,:) = 0.9;  p(2,1,:) = 0.9;
%! s50 = sparameters(p, f);
%! assert (s50.Impedance, 50);
%! s75 = sparameters(s50, 75);
%! assert (s75.Impedance, 75);

%!test
%! %% MATLAB compat: 4-port .NumPorts = 4
%! f = [1e9];
%! p = 0.1*eye(4);
%! s = sparameters(p, f);
%! assert (s.NumPorts, 4);

%!test
%! %% MATLAB compat: sparameters(filename) reads a Touchstone file
%! this_dir = fileparts (mfilename ('fullpath'));
%! s2p_file = fullfile (this_dir, '..', 'examples', 'case_01_2xThru.s2p');
%! if exist (s2p_file, 'file')
%!   s = sparameters (s2p_file);
%!   assert (isstruct (s));
%!   assert (isfield (s, 'Parameters'));
%!   assert (isfield (s, 'Frequencies'));
%!   assert (isfield (s, 'Impedance'));
%!   assert (isfield (s, 'NumPorts'));
%!   assert (s.NumPorts, 2);
%!   assert (s.Impedance, 50);
%!   assert (size (s.Parameters, 1), 2);
%!   assert (size (s.Parameters, 2), 2);
%!   assert (numel (s.Frequencies) > 0);
%! end
