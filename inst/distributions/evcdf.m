## Copyright (C) 2022 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the statistics package for GNU Octave.
##
## This program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} @var{p} = evcdf (@var{x})
## @deftypefnx {Function File} @var{p} = evcdf (@var{x}, @var{mu})
## @deftypefnx {Function File} @var{p} = evcdf (@var{x}, @var{mu}, @var{sigma})
## @deftypefnx {Function File} @var{p} = evcdf (@dots{}, "upper")
## @deftypefnx {Function File} [@var{p}, @var{plo}, @var{pup}] = evcdf (@var{x}, @var{mu}, @var{sigma}, @var{pcov})
## @deftypefnx {Function File} [@var{p}, @var{plo}, @var{pup}] = evcdf (@var{x}, @var{mu}, @var{sigma}, @var{pcov}, @var{alpha})
## @deftypefnx {Function File} [@var{p}, @var{plo}, @var{pup}] = evcdf (@dots{}, "upper")
##
## Extreme value cumulative distribution function (cdf).
##
## For each element of @var{x}, compute the cumulative distribution function
## (CDF) of the type 1 extreme values CDF at @var{x} of the normal distribution
## with location parameter @var{mu} and scale parameter @var{sigma}.  The size
## of @var{p} is the common size of @var{x}, @var{mu} and @var{sigma}.  A scalar
## input functions as a constant matrix of the same size as the other inputs.
##
## Default values are @var{mu} = 0, @var{sigma} = 1.
##
## When called with three output arguments, @code{[@var{p}, @var{plo},
## @var{pup}]} it computes the confidence bounds for @var{p} when the input
## parameters @var{mu} and @var{sigma} are estimates.  In such case, @var{pcov},
## a 2-by-2 matrix containing the covariance matrix of the estimated parameters,
## is necessary.  Optionally, @var{alpha} has a default value of 0.05, and
## specifies 100 * (1 - @var{alpha})% confidence bounds. @var{plo} and @var{pup}
## are arrays of the same size as @var{p} containing the lower and upper
## confidence bounds.
##
## The type 1 extreme value distribution is also known as the Gumbel
## distribution.  The version used here is suitable for modeling minima; the
## mirror image of this distribution can be used to model maxima by negating
## @var{x}.  If @var{y} has a Weibull distribution, then
## @code{@var{x} = log (@var{y})} has the type 1 extreme value distribution.
##
## @code{[@dots{}] = evcdf (@dots{}, "upper")} computes the upper tail
## probability of the extreme value distribution.
##
## @seealso{evinv, evpdf, evrnd, evfit, evlike, evstat}
## @end deftypefn

function [varargout] = evcdf (x, varargin)

  ## Check for valid number of input arguments
  if (nargin < 1 || nargin > 6)
    error ("evcdf: invalid number of input arguments.");
  endif
  ## Check for 'upper' flag
  if (nargin > 1 && strcmpi (varargin{end}, "upper"))
    uflag = true;
    varargin(end) = [];
  elseif (nargin > 1 && ischar (varargin{end}) && ...
          ! strcmpi (varargin{end}, "upper"))
    error ("evcdf: invalid argument for upper tail.");
  else
    uflag = false;
  endif
  ## Get extra arguments (if they exist) or add defaults
  if (numel (varargin) > 0)
    mu = varargin{1};
  else
    mu = 0;
  endif
  if (numel (varargin) > 1)
    sigma = varargin{2};
  else
    sigma = 1;
  endif
  if (numel (varargin) > 2)
    pcov = varargin{3};
    ## Check for valid covariance matrix 2x2
    if (! isequal (size (pcov), [2, 2]))
      error ("evcdf: invalid size of covariance matrix.");
    endif
  else
    ## Check that cov matrix is provided if 3 output arguments are requested
    if (nargout > 1)
      error ("evcdf: covariance matrix is required for confidence bounds.");
    endif
    pcov = [];
  endif
  if (numel (varargin) > 3)
    alpha = varargin{4};
    ## Check for valid alpha value
    if (! isnumeric (alpha) || numel (alpha) !=1 || alpha <= 0 || alpha >= 1)
      error ("evcdf: invalid value for alpha.");
    endif
  else
    alpha = 0.05;
  endif
  ## Check for common size of X, MU, and SIGMA
  if (! isscalar (x) || ! isscalar (mu) || ! isscalar (sigma))
    [err, x, mu, sigma] = common_size (x, mu, sigma);
    if (err > 0)
      error ("evcdf: X, MU, and SIGMA must be of common size or scalars.");
    endif
  endif
  ## Check for X, MU, and SIGMA being reals
  if (iscomplex (x) || iscomplex (mu) || iscomplex (sigma))
    error ("evcdf: X, MU, and SIGMA must not be complex.");
  endif
  ## Return NaNs for out of range parameters.
  sigma(sigma <= 0) = NaN;
  ## Compute extreme value cdf
  z = (x - mu) ./ sigma;
  if (uflag)
    p = exp (-exp (z));
  else
    p = -expm1 (-exp (z));
  endif
  ## Check for appropriate class
  if (isa (x, "single") || isa (mu, "single") || isa (sigma, "single"));
    is_class = "single";
  else
    is_class = "double";
  endif
  ## Prepare output
  varargout{1} = cast (p, is_class);
  if (nargout > 1)
    plo = NaN (size (z), is_class);
    pup = NaN (size (z), is_class);
  endif
  ## Check sigma
  if (isscalar (sigma))
    if (sigma > 0)
      sigma_p = true (size (z));
    else
      if (nargout == 3)
        varargout{2} = plo;
        varargout{3} = pup;
      endif
      return;
    endif
  else
    sigma_p = sigma > 0;
  endif
  ## Compute confidence bounds (if requested)
  if (nargout >= 2)
   zvar = (pcov(1,1) + 2 * pcov(1,2) * z(sigma_p) + ...
           pcov(2,2) * z(sigma_p) .^ 2) ./ (sigma .^ 2);
   if (any (zvar < 0))
      error ("evcdf: bad covariance matrix.");
   endif
   normz = -norminv (alpha / 2);
   halfwidth = normz * sqrt (zvar);
   zlo = z(sigma_p) - halfwidth;
   zup = z(sigma_p) + halfwidth;
   if (uflag)
     plo(sigma_p) = exp (-exp (zup));
     pup(sigma_p) = exp (-exp (zlo));
   else
     plo(sigma_p) = -expk1 (-exp (zlo));
     pup(sigma_p) = -expm1 (-exp (zup));
   endif
   varargout{2} = plo;
   varargout{3} = pup;
  endif

endfunction

## Test input validation
%!error<evcdf: invalid number of input arguments.> evcdf ()
%!error<evcdf: invalid number of input arguments.> evcdf (1,2,3,4,5,6,7)
%!error<evcdf: invalid argument for upper tail.> evcdf (1, 2, 3, 4, "uper")
%!error<evcdf: X, MU, and SIGMA must be of common size or scalars.> ...
%! evcdf (ones (3), ones (2), ones (2))
%!error<evcdf: invalid size of covariance matrix.> evcdf (2, 3, 4, [1, 2])
%!error<evcdf: covariance matrix is required for confidence bounds.> ...
%! [p, plo, pup] = evcdf (1, 2, 3)
%!error<evcdf: invalid value for alpha.> [p, plo, pup] = ...
%! evcdf (1, 2, 3, [1, 0; 0, 1], 0)
%!error<evcdf: invalid value for alpha.> [p, plo, pup] = ...
%! evcdf (1, 2, 3, [1, 0; 0, 1], 1.22)
%!error<evcdf: invalid value for alpha.> [p, plo, pup] = ...
%! evcdf (1, 2, 3, [1, 0; 0, 1], "alpha", "upper")
%!error<evcdf: X, MU, and SIGMA must not be complex.> evcdf (i, 2, 2)
%!error<evcdf: X, MU, and SIGMA must not be complex.> evcdf (2, i, 2)
%!error<evcdf: X, MU, and SIGMA must not be complex.> evcdf (2, 2, i)
%!error<evcdf: bad covariance matrix.> ...
%! [p, plo, pup] = evcdf (1, 2, 3, [1, 0; 0, -inf], 0.04)

## Test results
%!shared x, y
%! x = [-Inf, 1, 2, Inf];
%! y = [0, 0.6321, 0.9340, 1];
%!assert (evcdf (x, ones (1,4), ones (1,4)), y, 1e-4)
%!assert (evcdf (x, 1, ones (1,4)), y, 1e-4)
%!assert (evcdf (x, ones (1,4), 1), y, 1e-4)
%!assert (evcdf (x, [0, -Inf, NaN, Inf], 1), [0, 1, NaN, NaN], 1e-4)
%!assert (evcdf (x, 1, [Inf, NaN, -1, 0]), [NaN, NaN, NaN, NaN], 1e-4)
%!assert (evcdf ([x(1:2), NaN, x(4)], 1, 1), [y(1:2), NaN, y(4)], 1e-4)
%!assert (evcdf (x, "upper"), [1, 0.0660, 0.0006, 0], 1e-4)

## Test class of input preserved
%!assert (evcdf ([x, NaN], 1, 1), [y, NaN], 1e-4)
%!assert (evcdf (single ([x, NaN]), 1, 1), single ([y, NaN]), 1e-4)
%!assert (evcdf ([x, NaN], single (1), 1), single ([y, NaN]), 1e-4)
%!assert (evcdf ([x, NaN], 1, single (1)), single ([y, NaN]), 1e-4)
