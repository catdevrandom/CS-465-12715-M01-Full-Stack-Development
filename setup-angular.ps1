# Travlr Module 6 - builds the Angular admin SPA in app_admin
# Run from the travlr project root (folder containing app_api and app.js), on branch module6.

$ErrorActionPreference = 'Stop'

if (-not (Test-Path 'app_api')) { throw 'Run this from the travlr project root (the folder with app_api and app.js).' }
if (Test-Path 'app_admin') { throw 'app_admin already exists. Rename or delete it, then rerun.' }
$branch = (git branch --show-current)
if ($branch -ne 'module6') { throw "You are on '$branch'. Run: git checkout -b module6  then rerun." }

$env:NG_CLI_ANALYTICS = 'false'

function Run($cmd) {
    Write-Host ">> $cmd" -ForegroundColor Cyan
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $cmd" }
}

function W($path, $text) {
    $full = Join-Path (Get-Location) $path
    $dir = Split-Path $full
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $clean = $text.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($full, $clean, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------- Phase 2: create the Angular app (v17 to match the guide) ----------
Write-Host "Node version: $(node -v)  (Angular 17 needs 18.13+ or 20.9+)"
Run 'npm install -g @angular/cli@17'
Run 'ng new travlr-admin --defaults --directory app_admin --skip-git'

New-Item -ItemType Directory -Path 'app_admin\src\assets\css' -Force | Out-Null
if (Test-Path 'app_admin\src\styles.css') {
    Move-Item 'app_admin\src\styles.css' 'app_admin\src\assets\css\styles.css'
} else {
    W 'app_admin\src\assets\css\styles.css' ''
}

# angular.json: point at the moved stylesheet and the assets folder
$ajPath = 'app_admin\angular.json'
$aj = Get-Content $ajPath -Raw | ConvertFrom-Json
$arch = $aj.projects.'travlr-admin'.architect
foreach ($t in 'build', 'test') {
    if ($arch.$t) {
        $arch.$t.options.styles = @('src/assets/css/styles.css')
        $arch.$t.options.assets = @('src/favicon.ico', 'src/assets')
    }
}
W $ajPath ($aj | ConvertTo-Json -Depth 20)

# images from Express public folder
if (Test-Path 'public\images') {
    Copy-Item 'public\images' 'app_admin\src\assets\images' -Recurse -Force
} else {
    Write-Host 'WARNING: public\images not found. Copy your images into app_admin\src\assets\images yourself.' -ForegroundColor Yellow
}

# mock data from trips.json
if (Test-Path 'data\trips.json') {
    $json = Get-Content 'data\trips.json' -Raw
    W 'app_admin\src\app\data\trips.ts' ("export const trips: any[] = " + $json + ";`n")
} else {
    W 'app_admin\src\app\data\trips.ts' "export const trips: any[] = [];`n"
    Write-Host 'WARNING: data\trips.json not found. Paste your trip data into src\app\data\trips.ts.' -ForegroundColor Yellow
}

# ---------- Generate components and service with the CLI ----------
Push-Location app_admin
foreach ($c in 'trip-listing', 'trip-card', 'add-trip', 'edit-trip') {
    Run "ng generate component $c --skip-tests"
}
Run 'ng generate service services/trip-data --skip-tests'
Pop-Location

$app = 'app_admin\src\app'

# ---------- index.html ----------
W 'app_admin\src\index.html' @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Travlr Getaways Admin</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">
</head>
<body>
  <app-root>Loading...</app-root>
  <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
  <script src="https://code.jquery.com/jquery-3.7.1.slim.min.js" crossorigin="anonymous"></script>
</body>
</html>
'@

# ---------- app config, routes, root component ----------
W "$app\app.config.ts" @'
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes), provideHttpClient()]
};
'@

W "$app\app.routes.ts" @'
import { Routes } from '@angular/router';
import { AddTripComponent } from './add-trip/add-trip.component';
import { EditTripComponent } from './edit-trip/edit-trip.component';
import { TripListingComponent } from './trip-listing/trip-listing.component';

export const routes: Routes = [
  { path: 'add-trip', component: AddTripComponent },
  { path: 'edit-trip', component: EditTripComponent },
  { path: '', component: TripListingComponent, pathMatch: 'full' }
];
'@

W "$app\app.component.ts" @'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  title = 'Travlr Getaways Admin';
}
'@

W "$app\app.component.html" @'
<nav class="navbar navbar-light bg-light">
  <div class="container-fluid">
    <a class="navbar-brand" href="/">{{ title }}</a>
  </div>
</nav>

<div class="container">
  <router-outlet></router-outlet>
</div>
'@

# ---------- model and service ----------
W "$app\models\trip.ts" @'
export interface Trip {
  _id: string;
  code: string;
  name: string;
  length: string;
  start: Date;
  resort: string;
  perPerson: string;
  image: string;
  description: string;
}
'@

W "$app\services\trip-data.service.ts" @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Trip } from '../models/trip';

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
}
'@

# ---------- trip listing ----------
W "$app\trip-listing\trip-listing.component.ts" @'
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
'@

W "$app\trip-listing\trip-listing.component.html" @'
<div class="d-flex justify-content-between align-items-center my-3">
  <h2 class="m-0">Trips</h2>
  <button type="button" class="btn btn-info" (click)="addTrip()">Add Trip</button>
</div>

<div class="row">
  <div *ngFor="let trip of trips" class="col-md-4 mb-3">
    <app-trip-card [trip]="trip" (deleted)="getStuff()"></app-trip-card>
  </div>
</div>
'@

# ---------- trip card ----------
W "$app\trip-card\trip-card.component.ts" @'
import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { Trip } from '../models/trip';
import { TripDataService } from '../services/trip-data.service';

@Component({
  selector: 'app-trip-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './trip-card.component.html',
  styleUrl: './trip-card.component.css'
})
export class TripCardComponent implements OnInit {
  @Input('trip') trip: any;
  @Output() deleted = new EventEmitter<string>();

  constructor(private router: Router, private tripDataService: TripDataService) {}

  ngOnInit(): void {}

  public editTrip(trip: Trip): void {
    localStorage.removeItem('tripCode');
    localStorage.setItem('tripCode', trip.code);
    this.router.navigate(['edit-trip']);
  }

  public deleteTrip(trip: Trip): void {
    if (!confirm('Delete ' + trip.name + '?')) { return; }
    this.tripDataService.deleteTrip(trip.code).subscribe({
      next: () => this.deleted.emit(trip.code),
      error: (error: any) => console.log('Error: ' + error)
    });
  }
}
'@

W "$app\trip-card\trip-card.component.html" @'
<div class="card h-100">
  <div class="card-header">{{ trip.name }}</div>
  <img src="assets/images/{{ trip.image }}" alt="trip thumbnail" class="card-img-top">
  <div class="card-body">
    <h6 class="card-subtitle mb-2 text-muted">{{ trip.resort }}</h6>
    <p class="card-subtitle mt-3 mb-3 text-muted">
      {{ trip.length }} only {{ trip.perPerson | currency:'USD':'symbol' }} per person
    </p>
    <p class="card-text" [innerHTML]="trip.description"></p>
  </div>
  <div class="card-footer">
    <button type="button" class="btn btn-info" (click)="editTrip(trip)">Edit Trip</button>
    <button type="button" class="btn btn-danger ms-2" (click)="deleteTrip(trip)">Delete</button>
  </div>
</div>
'@

# ---------- add trip ----------
W "$app\add-trip\add-trip.component.ts" @'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TripDataService } from '../services/trip-data.service';

@Component({
  selector: 'app-add-trip',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './add-trip.component.html',
  styleUrl: './add-trip.component.css'
})
export class AddTripComponent implements OnInit {
  public addForm!: FormGroup;
  submitted = false;

  fields = [
    { key: 'code', label: 'Code', type: 'text' },
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'length', label: 'Length', type: 'text' },
    { key: 'start', label: 'Start', type: 'date' },
    { key: 'resort', label: 'Resort', type: 'text' },
    { key: 'perPerson', label: 'Per Person', type: 'text' },
    { key: 'image', label: 'Image Name', type: 'text' },
    { key: 'description', label: 'Description', type: 'text' }
  ];

  constructor(
    private formBuilder: FormBuilder,
    private router: Router,
    private tripService: TripDataService
  ) {}

  ngOnInit() {
    const group: any = { _id: [] };
    for (const f of this.fields) {
      group[f.key] = ['', Validators.required];
    }
    this.addForm = this.formBuilder.group(group);
  }

  public onSubmit() {
    this.submitted = true;
    if (this.addForm.valid) {
      this.tripService.addTrip(this.addForm.value).subscribe({
        next: (data: any) => {
          console.log(data);
          this.router.navigate(['']);
        },
        error: (error: any) => {
          console.log('Error: ' + error);
        }
      });
    }
  }

  get f() { return this.addForm.controls; }
}
'@

W "$app\add-trip\add-trip.component.html" @'
<div class="col-md-6 mx-auto my-3">
  <h2 class="text-center">Add Trip</h2>
  <form *ngIf="addForm" [formGroup]="addForm" (ngSubmit)="onSubmit()">
    <div class="mb-3" *ngFor="let field of fields">
      <label class="form-label">{{ field.label }}:</label>
      <input [type]="field.type" [formControlName]="field.key" [placeholder]="field.label"
             class="form-control" [ngClass]="{ 'is-invalid': submitted && f[field.key].errors }">
      <div class="invalid-feedback">{{ field.label }} is required</div>
    </div>
    <button type="submit" class="btn btn-info">Save</button>
    <a routerLink="/" class="btn btn-secondary ms-2" href="/">Cancel</a>
  </form>
</div>
'@

# ---------- edit trip ----------
W "$app\edit-trip\edit-trip.component.ts" @'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { TripDataService } from '../services/trip-data.service';
import { Trip } from '../models/trip';

@Component({
  selector: 'app-edit-trip',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './edit-trip.component.html',
  styleUrl: './edit-trip.component.css'
})
export class EditTripComponent implements OnInit {
  public editForm!: FormGroup;
  trip!: Trip;
  submitted = false;
  message: string = '';

  fields = [
    { key: 'code', label: 'Code', type: 'text' },
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'length', label: 'Length', type: 'text' },
    { key: 'start', label: 'Start', type: 'date' },
    { key: 'resort', label: 'Resort', type: 'text' },
    { key: 'perPerson', label: 'Per Person', type: 'text' },
    { key: 'image', label: 'Image Name', type: 'text' },
    { key: 'description', label: 'Description', type: 'text' }
  ];

  constructor(
    private formBuilder: FormBuilder,
    private router: Router,
    private tripDataService: TripDataService
  ) {}

  ngOnInit(): void {
    const tripCode = localStorage.getItem('tripCode');
    if (!tripCode) {
      alert("Something wrong, couldn't find where I stashed tripCode!");
      this.router.navigate(['']);
      return;
    }

    console.log('EditTripComponent::ngOnInit');
    console.log('tripcode:' + tripCode);

    const group: any = { _id: [] };
    for (const f of this.fields) {
      group[f.key] = [f.key === 'code' ? tripCode : '', Validators.required];
    }
    this.editForm = this.formBuilder.group(group);

    this.tripDataService.getTrip(tripCode).subscribe({
      next: (value: any) => {
        this.trip = value;
        if (!value || value.length === 0) {
          this.message = 'No Trip Retrieved!';
        } else {
          const t = value[0];
          // Mongo returns an ISO date string; the date input needs yyyy-MM-dd
          this.editForm.patchValue({
            ...t,
            start: t.start ? String(t.start).substring(0, 10) : ''
          });
          this.message = 'Trip: ' + tripCode + ' retrieved';
        }
        console.log(this.message);
      },
      error: (error: any) => {
        console.log('Error: ' + error);
      }
    });
  }

  public onSubmit() {
    this.submitted = true;
    if (this.editForm.valid) {
      this.tripDataService.updateTrip(this.editForm.value).subscribe({
        next: (value: any) => {
          console.log(value);
          this.router.navigate(['']);
        },
        error: (error: any) => {
          console.log('Error: ' + error);
        }
      });
    }
  }

  get f() { return this.editForm.controls; }
}
'@

W "$app\edit-trip\edit-trip.component.html" @'
<div class="col-md-6 mx-auto my-3">
  <h2 class="text-center">Edit Trip</h2>
  <form *ngIf="editForm" [formGroup]="editForm" (ngSubmit)="onSubmit()">
    <div class="mb-3" *ngFor="let field of fields">
      <label class="form-label">{{ field.label }}:</label>
      <input [type]="field.type" [formControlName]="field.key" [placeholder]="field.label"
             [readonly]="field.key === 'code'"
             class="form-control" [ngClass]="{ 'is-invalid': submitted && f[field.key].errors }">
      <div class="invalid-feedback">{{ field.label }} is required</div>
    </div>
    <button type="submit" class="btn btn-info">Save</button>
    <a href="/" class="btn btn-secondary ms-2">Cancel</a>
  </form>
</div>
'@

Write-Host ''
Write-Host 'Angular side done.' -ForegroundColor Green
Write-Host 'Next: add the backend code (routes, controllers, CORS), restart Express, then:'
Write-Host '  cd app_admin'
Write-Host '  ng serve'
