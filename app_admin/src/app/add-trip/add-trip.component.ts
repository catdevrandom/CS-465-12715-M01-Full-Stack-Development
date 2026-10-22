import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TripDataService } from '../services/trip-data.service';

@Component({
  selector: 'app-add-trip',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
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