import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TripCardComponent } from '../trip-card/trip-card.component';
import { TripDataService } from '../services/trip-data.service';
import { Trip } from '../models/trip';
import { trips as mockTrips } from '../data/trips';

@Component({
  selector: 'app-trip-listing',
  standalone: true,
  imports: [CommonModule, TripCardComponent],
  templateUrl: './trip-listing.component.html',
  styleUrl: './trip-listing.component.css'
})
export class TripListingComponent implements OnInit {
  trips: Array<any> = [];
  message: string = '';

  // Set to true to render the mock data in src/app/data/trips.ts (functional testing)
  useMock = false;

  constructor(private tripDataService: TripDataService, private router: Router) {}

  public addTrip(): void {
    this.router.navigate(['add-trip']);
  }

  public getStuff(): void {
    if (this.useMock) {
      this.trips = mockTrips;
      this.message = 'Showing mock data';
      return;
    }
    this.tripDataService.getTrips().subscribe({
      next: (value: Trip[]) => {
        this.trips = value;
        this.message = value.length > 0
          ? 'There are ' + value.length + ' trips available.'
          : 'There were no trips retrieved from the database';
        console.log(this.message);
      },
      error: (error: any) => {
        console.log('Error: ' + error);
      }
    });
  }

  ngOnInit(): void {
    console.log('ngOnInit');
    this.getStuff();
  }
}