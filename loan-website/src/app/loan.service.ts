import { Inject, Injectable, PLATFORM_ID } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { environment } from '../environments/environment'; 
import { isPlatformBrowser } from '@angular/common';

export interface Loan {
  loanID: string;
  borrowerName: string;
  repaymentAmount: number;
  fundingAmount: number;
}

@Injectable({
  providedIn: 'root'
})
export class LoanService {
  private apiUrl = '/api/loan';
  
  private httpOptions = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json'
    })
  };

  constructor(
    private http: HttpClient,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    // Check if we're in the browser
    if (isPlatformBrowser(this.platformId)) {
      // When running locally (not in Docker), use port 8080
      this.apiUrl = window.location.hostname === 'localhost' && window.location.port === '4200' 
        ? 'http://localhost:8080/api/loan' 
        : '/api/loan';
    } else {
      // Server-side rendering - use the backend service name
      this.apiUrl = 'http://backend:5000/api/loan';
    }
  }

  // Get all loans
  getAllLoans(): Observable<Loan[]> {
    const url = `${this.apiUrl}/all`;
    console.log('Fetching all loans from:', url);
    return this.http.get<Loan[]>(url).pipe(
      tap(loans => console.log('Received loans:', loans)),
      catchError(this.handleError)
    );
  }

  // Get loan by borrower name
// Get loan by borrower name
// Get loans by borrower name
  getLoanByBorrowerName(borrowerName: string): Observable<Loan[]> {
    const url = `${this.apiUrl}?borrowerName=${encodeURIComponent(borrowerName)}`;
    console.log('Searching loans by borrower name:', url);
    return this.http.get<Loan[]>(url).pipe(
      tap(loans => console.log('Received loans by borrower name:', loans)),
      catchError(this.handleError)
    );
  }

  // Get loan by ID
  getLoanById(loanId: string): Observable<Loan> {
    const url = `${this.apiUrl}/${loanId}`;
    console.log('Fetching loan by ID:', url);
    return this.http.get<Loan>(url).pipe(
      tap(loan => console.log('Received loan by ID:', loan)),
      catchError(this.handleError)
    );
  }

  // Add a new loan
  addLoan(loan: Omit<Loan, 'loanID'>): Observable<Loan> {
    console.log('Adding new loan:', loan);
    return this.http.post<Loan>(this.apiUrl, loan, this.httpOptions).pipe(
      tap(newLoan => console.log('Added new loan:', newLoan)),
      catchError(this.handleError)
    );
  }

  // Delete a loan
// Delete a loan
  deleteLoan(loanID: string): Observable<any> {
    const url = `${this.apiUrl}/${loanID}`;
    console.log('Deleting loan with ID:', url);
    return this.http.delete(url, { responseType: 'text' }).pipe(
      tap(response => console.log('Delete response:', response)),
      catchError(this.handleError)
    );
  }

  private handleError(error: HttpErrorResponse) {
    console.error('API Error Details:', error);
    
    let errorMessage = '';
    if (error.error instanceof ErrorEvent) {
      errorMessage = `Client Error: ${error.error.message}`;
    } else {
      errorMessage = `Server Error: ${error.status} - ${error.statusText}`;
      console.error('Server response:', error.error);
    }
    
    return throwError(() => new Error(errorMessage));
  }
}