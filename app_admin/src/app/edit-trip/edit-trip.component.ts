import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { TripDataService } from '../services/trip-data.service';
import { Trip } from '../models/trip';

@Component({
  selector: 'app-edit-trip',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
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