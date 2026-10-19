import { Inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { BROWSER_STORAGE } from '../storage';
import { User } from '../models/user';
import { AuthResponse } from '../models/auth-response';
import { TripDataService } from './trip-data.service';

@Injectable({ providedIn: 'root' })
export class AuthenticationService {
  constructor(
    @Inject(BROWSER_STORAGE) private storage: Storage,
    private tripDataService: TripDataService
  ) {}

  // Get our token from storage (key: travlr-token)
  public getToken(): string {
    const out = this.storage.getItem('travlr-token');
    return out ? out : '';
  }

  // Save our token to storage
  public saveToken(token: string): void {
    this.storage.setItem('travlr-token', token);
  }

  // Log out by removing the token
  public logout(): void {
    this.storage.removeItem('travlr-token');
  }

  // True only if a token exists and has not expired
  public isLoggedIn(): boolean {
    const token: string = this.getToken();
    if (!token) {
      return false;
    }
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.exp > Date.now() / 1000;
    } catch {
      return false;
    }
  }

  // Only call after isLoggedIn() returns true
  public getCurrentUser(): User {
    const token: string = this.getToken();
    const { email, name } = JSON.parse(atob(token.split('.')[1]));
    return { email, name } as User;
  }

  // Log in and store the returned token
  public login(user: User, passwd: string): Observable<AuthResponse> {
    return this.tripDataService.login(user, passwd).pipe(
      tap((value: AuthResponse) => {
        if (value && value.token) {
          this.saveToken(value.token);
        }
      })
    );
  }

  // Register and store the returned token (the API logs the user in)
  public register(user: User, passwd: string): Observable<AuthResponse> {
    return this.tripDataService.register(user, passwd).pipe(
      tap((value: AuthResponse) => {
        if (value && value.token) {
          this.saveToken(value.token);
        }
      })
    );
  }
}