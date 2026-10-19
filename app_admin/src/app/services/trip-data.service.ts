import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Trip } from '../models/trip';
import { User } from '../models/user';
import { AuthResponse } from '../models/auth-response';

@Injectable({ providedIn: 'root' })
export class TripDataService {
  private apiBaseUrl = 'http://localhost:3000/api/';
  private tripUrl = `${this.apiBaseUrl}trips`;

  constructor(private http: HttpClient) {}

  getTrips(): Observable<Trip[]> {
    return this.http.get<Trip[]>(this.tripUrl);
  }

  getTrip(tripCode: string): Observable<Trip[]> {
    return this.http.get<Trip[]>(`${this.tripUrl}/${tripCode}`);
  }

  addTrip(formData: Trip): Observable<Trip> {
    return this.http.post<Trip>(this.tripUrl, formData);
  }

  updateTrip(formData: Trip): Observable<Trip> {
    return this.http.put<Trip>(`${this.tripUrl}/${formData.code}`, formData);
  }

  deleteTrip(tripCode: string): Observable<any> {
    return this.http.delete(`${this.tripUrl}/${tripCode}`);
  }

  // Call to our /login endpoint, returns a JWT
  login(user: User, passwd: string): Observable<AuthResponse> {
    return this.handleAuthAPICall('login', user, passwd);
  }

  // Call to our /register endpoint, creates a user and returns a JWT
  register(user: User, passwd: string): Observable<AuthResponse> {
    return this.handleAuthAPICall('register', user, passwd);
  }

  // Helper used by both login and register
  handleAuthAPICall(endpoint: string, user: User, passwd: string): Observable<AuthResponse> {
    const formData = {
      name: user.name,
      email: user.email,
      password: passwd
    };
    return this.http.post<AuthResponse>(`${this.apiBaseUrl}${endpoint}`, formData);
  }
}