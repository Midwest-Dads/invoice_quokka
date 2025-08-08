import { Client } from './clients';

export interface InvoiceItem {
  id: string;
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
  createdAt: string;
  updatedAt: string;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  issueDate: string;
  dueDate: string;
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  taxRate: number;
  notes: string;
  subtotal: number;
  taxAmount: number;
  totalAmount: number;
  client: Client;
  invoiceItems: InvoiceItem[];
  createdAt: string;
  updatedAt: string;
}