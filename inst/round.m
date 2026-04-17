## -*- texinfo -*-
## @deftypefn  {Function File} {@var{y} =} round (@var{x})
## @deftypefnx {Function File} {@var{y} =} round (@var{x}, @var{n})
## Round to nearest integer, or to @var{n} decimal places.
##
## @strong{Form 1}: @code{round(x)} — identical to Octave's built-in
## @code{round}.  Delegates directly to the built-in with no overhead.
##
## @strong{Form 2}: @code{round(x, n)} — MATLAB-compatible syntax that
## rounds @var{x} to @var{n} decimal places.  For example,
## @code{round(3.456, 2)} returns @code{3.46}.  Negative @var{n} rounds
## to the left of the decimal point: @code{round(1234, -2)} returns
## @code{1200}.
##
## This shim exists because Octave's built-in @code{round} (as of 11.1)
## does not accept a second argument.  IEEE P370 TG3 code
## (@code{qualityCheck.m}) uses @code{round(x, n)}, so this function
## enables that code to run unmodified in Octave.
##
## @seealso{floor, ceil, fix}
## @end deftypefn

function y = round (x, n)

  if nargin == 1
    y = builtin ('round', x);
  elseif nargin == 2
    factor = 10 .^ n;
    y = builtin ('round', x .* factor) ./ factor;
  else
    print_usage ();
  end

endfunction

%!test
%! %% 1-arg form: delegates to built-in (integer rounding)
%! assert (round (3.7), 4);
%! assert (round (-1.2), -1);
%! assert (round (0), 0);

%!test
%! %% 2-arg form: round to n decimal places (MATLAB-compatible)
%! assert (round (3.456, 2), 3.46);
%! assert (round (3.456, 1), 3.5);
%! assert (round (3.456, 0), 3);

%!test
%! %% Negative n: round to the left of the decimal point
%! assert (round (1234, -2), 1200);
%! assert (round (1250, -2), 1300);

%!test
%! %% Vectorised input
%! assert (round ([1.23, 4.56, 7.89], 1), [1.2, 4.6, 7.9]);

%!test
%! %% pi to 4 decimal places
%! assert (round (pi, 4), 3.1416);
