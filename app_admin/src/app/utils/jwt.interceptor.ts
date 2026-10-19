import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthenticationService } from '../services/authentication.service';

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const authenticationService = inject(AuthenticationService);

  // Do not attach a token to the login and register calls
  const isAuthAPI = req.url.endsWith('/login') || req.url.endsWith('/register');

  if (authenticationService.isLoggedIn() && !isAuthAPI) {
    const token = authenticationService.getToken();
    const authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
    return next(authReq);
  }

  return next(req);
};
