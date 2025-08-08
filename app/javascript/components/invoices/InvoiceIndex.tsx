import { visit } from "@hotwired/turbo";
import { Invoice } from "../../types/invoices";

interface InvoiceIndexProps {
  invoices: Invoice[];
}

const statusColors = {
  draft: "badge-secondary",
  sent: "badge-warning", 
  paid: "badge-success",
  overdue: "badge-error",
  cancelled: "badge-neutral"
};

export default function InvoiceIndex({ invoices }: InvoiceIndexProps) {
  const handleNewInvoice = () => {
    visit("/invoices/new");
  };

  const handleViewInvoice = (invoiceId: string) => {
    visit(`/invoices/${invoiceId}`);
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
        <h1 className="text-3xl font-bold">Invoices</h1>
        <button
          onClick={handleNewInvoice}
          className="btn btn-primary"
        >
          New Invoice
        </button>
      </div>

      {/* Invoices Table */}
      {invoices.length === 0 ? (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body text-center">
            <h2 className="card-title justify-center">No invoices yet</h2>
            <p>Create your first invoice to get started.</p>
            <div className="card-actions justify-center">
              <button onClick={handleNewInvoice} className="btn btn-primary">
                Create First Invoice
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <div className="overflow-x-auto">
              <table className="table">
                <thead>
                  <tr>
                    <th>Invoice #</th>
                    <th>Client</th>
                    <th>Issue Date</th>
                    <th>Due Date</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {invoices.map((invoice) => (
                    <tr key={invoice.id} className="hover">
                      <td className="font-semibold">{invoice.invoiceNumber}</td>
                      <td>{invoice.client.name}</td>
                      <td>{formatDate(invoice.issueDate)}</td>
                      <td>{formatDate(invoice.dueDate)}</td>
                      <td className="font-semibold">{formatCurrency(invoice.totalAmount)}</td>
                      <td>
                        <span className={`badge ${statusColors[invoice.status]} capitalize`}>
                          {invoice.status}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleViewInvoice(invoice.id)}
                            className="btn btn-sm btn-outline"
                          >
                            View
                          </button>
                          <button
                            onClick={() => visit(`/invoices/${invoice.id}/edit`)}
                            className="btn btn-sm btn-secondary"
                          >
                            Edit
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}