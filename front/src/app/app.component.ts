// app.component.ts
import { Component, OnInit } from '@angular/core';
import { ProductService } from './services/product.service';
import { Product } from './product';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  products: Product[] = [];
  selectedProduct: Product = { id: 0, name: '', price: 0, host: '' };
  isEditing = false;
  showForm = false;

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.productService.getProducts().subscribe(
      products => this.products = products
    );
  }

  startAdd(): void {
    this.selectedProduct = { id: 0, name: '', price: 0, host:'' };
    this.isEditing = false;
    this.showForm = true;
  }

  startEdit(product: Product): void {
    this.selectedProduct = { ...product };
    this.isEditing = true;
    this.showForm = true;
  }

  submitForm(): void {
    if (this.isEditing) {
      this.productService.updateProduct(this.selectedProduct).subscribe(() => {
        this.loadProducts();
        this.cancelEdit();
      });
    } else {
      this.productService.createProduct(this.selectedProduct).subscribe(() => {
        this.loadProducts();
        this.cancelEdit();
      });
    }
  }

  deleteProduct(id: number): void {
    this.productService.deleteProduct(id).subscribe(() => {
      this.products = this.products.filter(p => p.id !== id);
    });
  }

  cancelEdit(): void {
    this.showForm = false;
    this.selectedProduct = { id: 0, name: '', price: 0, host:'' };
    this.isEditing = false;
  }
}
