import { visit } from "@hotwired/turbo";
import { Invoice } from "../../types/invoices";

interface InvoiceShowProps {
  invoice: Invoice;
}

const statusColors = {
  draft: "badge-secondary",
  sent: "badge-warning", 
  paid: "badge-success",
  overdue: "badge-error",
  cancelled: "badge-neutral"
};

export default function InvoiceShow({ invoice }: InvoiceShowProps) {
  const handleEdit = () => {
    visit(`/invoices/${invoice.id}/edit`);
  };

  const handleBack = () => {
    visit("/invoices");
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Invoice {invoice.invoiceNumber}</h1>
          <span className={`badge ${statusColors[invoice.status]} capitalize`}>
            {invoice.status}
          </span>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleEdit}
            className="btn btn-primary"
          >
            Edit Invoice
          </button>
          <button
            onClick={handleBack}
            className="btn btn-outline"
          >
            Back to Invoices
          </button>
        </div>
      </div>

      {/* Invoice Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Bill To */}
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Bill To</h2>
            <div>
              <p className="font-semibold text-lg">{invoice.client.name}</p>
              <p>{invoice.client.email}</p>
              {invoice.client.phone && <p>{invoice.client.phone}</p>}
              {invoice.client.address && (
                <p className="whitespace-pre-line mt-2">{invoice.client.address}</p>
              )}
            </div>
          </div>
        </div>

        {/* Invoice Info */}
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Invoice Details</h2>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Invoice Number:</span>
                <span className="font-semibold">{invoice.invoiceNumber}</span>
              </div>
              <div className="flex justify-between">
                <span>Issue Date:</span>
                <span>{formatDate(invoice.issueDate)}</span>
              </div>
              <div className="flex justify-between">
                <span>Due Date:</span>
                <span>{formatDate(invoice.dueDate)}</span>
              </div>
              <div className="flex justify-between">
                <span>Status:</span>
                <span className={`badge ${statusColors[invoice.status]} capitalize`}>
                  {invoice.status}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Line Items */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Items</h2>
          
          {invoice.invoiceItems && invoice.invoiceItems.length > 0 ? (
            <>
              <div className="overflow-x-auto">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Description</th>
                      <th className="text-right">Quantity</th>
                      <th className="text-right">Unit Price</th>
                      <th className="text-right">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {invoice.invoiceItems.map((item) => (
                      <tr key={item.id}>
                        <td>{item.description}</td>
                        <td className="text-right">{item.quantity}</td>
                        <td className="text-right">{formatCurrency(item.unitPrice)}</td>
                        <td className="text-right font-semibold">{formatCurrency(item.total)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Totals */}
              <div className="divider"></div>
              <div className="flex justify-end">
                <div className="w-64 space-y-2">
                  <div className="flex justify-between">
                    <span>Subtotal:</span>
                    <span>{formatCurrency(invoice.subtotal)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Tax ({(invoice.taxRate * 100).toFixed(1)}%):</span>
                    <span>{formatCurrency(invoice.taxAmount)}</span>
                  </div>
                  <div className="flex justify-between font-bold text-lg border-t pt-2">
                    <span>Total:</span>
                    <span>{formatCurrency(invoice.totalAmount)}</span>
                  </div>
                </div>
              </div>
            </>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500">No items added to this invoice yet.</p>
              <button
                onClick={handleEdit}
                className="btn btn-primary mt-4"
              >
                Add Items
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Notes */}
      {invoice.notes && (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Notes</h2>
            <p className="whitespace-pre-line">{invoice.notes}</p>
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Actions</h2>
          
          <div className="flex gap-2">
            <button
              onClick={() => visit(`/clients/${invoice.client.id}`)}
              className="btn btn-outline"
            >
              View Client
            </button>
            <button
              onClick={handleEdit}
              className="btn btn-secondary"
            >
              Edit Invoice
            </button>
            {invoice.status === 'draft' && (
              <button
                className="btn btn-success"
                onClick={() => {
                  // TODO: Implement send functionality
                  alert('Send functionality coming soon!');
                }}
              >
                Send Invoice
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}