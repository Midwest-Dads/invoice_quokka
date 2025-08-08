import { useState } from "react";
import { visit } from "@hotwired/turbo";
import { useApiRequest } from "../../hooks/useApiRequest";
import { Invoice, InvoiceItem } from "../../types/invoices";
import { Client } from "../../types/clients";
import { Listbox, ListboxButton, ListboxOption, ListboxOptions } from "@headlessui/react";
import { ChevronDown, Check, Plus, Trash2 } from "lucide-react";

interface InvoiceCreateProps {
  invoice: Invoice;
  clients: Client[];
}

export default function InvoiceCreate({ invoice, clients }: InvoiceCreateProps) {
  const [formData, setFormData] = useState({
    client_id: "",
    invoice_number: "",
    issue_date: new Date().toISOString().split('T')[0],
    due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    tax_rate: 0,
    notes: "",
  });

  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [lineItems, setLineItems] = useState<Partial<InvoiceItem>[]>([
    { description: "", quantity: 1, unitPrice: 0 }
  ]);

  const { loading, makeRequest, getFieldError } = useApiRequest({
    onSuccess: (data) => {
      visit(`/invoices/${data.id}`);
    },
    onError: (error) => {
      console.error("Failed to create invoice:", error);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const submitData = {
      ...formData,
      client_id: selectedClient?.id || "",
    };

    const result = await makeRequest("POST", "/api/v1/invoices", {
      invoice: submitData,
    });

    // If invoice created successfully, add line items
    if (result && lineItems.length > 0 && lineItems[0].description) {
      for (const item of lineItems) {
        if (item.description && item.quantity && item.unitPrice !== undefined) {
          await makeRequest("POST", `/api/v1/invoices/${result.id}/invoice_items`, {
            invoice_item: item,
          });
        }
      }
      visit(`/invoices/${result.id}`);
    }
  };

  const handleCancel = () => {
    visit("/invoices");
  };

  const addLineItem = () => {
    setLineItems([...lineItems, { description: "", quantity: 1, unitPrice: 0 }]);
  };

  const removeLineItem = (index: number) => {
    setLineItems(lineItems.filter((_, i) => i !== index));
  };

  const updateLineItem = (index: number, field: keyof InvoiceItem, value: string | number) => {
    const updated = [...lineItems];
    updated[index] = { ...updated[index], [field]: value };
    setLineItems(updated);
  };

  const calculateSubtotal = () => {
    return lineItems.reduce((sum, item) => {
      return sum + ((item.quantity || 0) * (item.unitPrice || 0));
    }, 0);
  };

  const calculateTotal = () => {
    const subtotal = calculateSubtotal();
    const tax = subtotal * (formData.tax_rate / 100);
    return subtotal + tax;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Create New Invoice</h1>
        <button onClick={handleCancel} className="btn btn-outline">
          Cancel
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Invoice Details */}
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Invoice Details</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Client Selection */}
              <div className="form-control">
                <label className="label">
                  <span className="label-text">Client</span>
                </label>
                <Listbox value={selectedClient} onChange={setSelectedClient}>
                  <ListboxButton className={`input input-bordered w-full text-left ${getFieldError('clientId') ? 'input-error' : ''}`}>
                    {selectedClient?.name || "Select client"}
                    <ChevronDown className="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none w-5 h-5" />
                  </ListboxButton>
                  <ListboxOptions className="absolute z-10 mt-1 w-full bg-base-100 shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
                    {clients.map((client) => (
                      <ListboxOption
                        key={client.id}
                        value={client}
                        className="relative cursor-default select-none py-2 pl-10 pr-4 hover:bg-base-200"
                      >
                        {client.name}
                        {selectedClient?.id === client.id && (
                          <span className="absolute inset-y-0 left-0 flex items-center pl-3">
                            <Check className="h-5 w-5" aria-hidden="true" />
                          </span>
                        )}
                      </ListboxOption>
                    ))}
                  </ListboxOptions>
                </Listbox>
                {getFieldError('clientId') && (
                  <label className="label">
                    <span className="label-text-alt text-error">{getFieldError('clientId')}</span>
                  </label>
                )}
              </div>

              {/* Invoice Number */}
              <div className="form-control">
                <label className="label">
                  <span className="label-text">Invoice Number</span>
                </label>
                <input
                  type="text"
                  className={`input input-bordered ${getFieldError('invoiceNumber') ? 'input-error' : ''}`}
                  placeholder="Auto-generated if empty"
                  value={formData.invoice_number}
                  onChange={(e) => setFormData(prev => ({ ...prev, invoice_number: e.target.value }))}
                />
              </div>

              {/* Issue Date */}
              <div className="form-control">
                <label className="label">
                  <span className="label-text">Issue Date</span>
                </label>
                <input
                  type="date"
                  className="input input-bordered"
                  value={formData.issue_date}
                  onChange={(e) => setFormData(prev => ({ ...prev, issue_date: e.target.value }))}
                />
              </div>

              {/* Due Date */}
              <div className="form-control">
                <label className="label">
                  <span className="label-text">Due Date</span>
                </label>
                <input
                  type="date"
                  className="input input-bordered"
                  value={formData.due_date}
                  onChange={(e) => setFormData(prev => ({ ...prev, due_date: e.target.value }))}
                />
              </div>

              {/* Tax Rate */}
              <div className="form-control">
                <label className="label">
                  <span className="label-text">Tax Rate (%)</span>
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  max="100"
                  className="input input-bordered"
                  value={formData.tax_rate}
                  onChange={(e) => setFormData(prev => ({ ...prev, tax_rate: Number(e.target.value) }))}
                />
              </div>
            </div>

            {/* Notes */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Notes</span>
              </label>
              <textarea
                className="textarea textarea-bordered"
                placeholder="Additional notes or terms"
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                rows={3}
              />
            </div>
          </div>
        </div>

        {/* Line Items */}
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <div className="flex justify-between items-center">
              <h2 className="card-title">Line Items</h2>
              <button
                type="button"
                onClick={addLineItem}
                className="btn btn-sm btn-outline"
              >
                <Plus className="w-4 h-4" />
                Add Item
              </button>
            </div>

            <div className="space-y-4">
              {lineItems.map((item, index) => (
                <div key={index} className="grid grid-cols-12 gap-2 items-end">
                  <div className="col-span-5">
                    <input
                      type="text"
                      className="input input-bordered input-sm w-full"
                      placeholder="Description"
                      value={item.description || ""}
                      onChange={(e) => updateLineItem(index, 'description', e.target.value)}
                    />
                  </div>
                  <div className="col-span-2">
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      className="input input-bordered input-sm w-full"
                      placeholder="Qty"
                      value={item.quantity || ""}
                      onChange={(e) => updateLineItem(index, 'quantity', Number(e.target.value))}
                    />
                  </div>
                  <div className="col-span-2">
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      className="input input-bordered input-sm w-full"
                      placeholder="Price"
                      value={item.unitPrice || ""}
                      onChange={(e) => updateLineItem(index, 'unitPrice', Number(e.target.value))}
                    />
                  </div>
                  <div className="col-span-2 text-right font-semibold">
                    ${((item.quantity || 0) * (item.unitPrice || 0)).toFixed(2)}
                  </div>
                  <div className="col-span-1">
                    {lineItems.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeLineItem(index)}
                        className="btn btn-sm btn-error btn-outline"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Totals */}
            <div className="divider"></div>
            <div className="flex justify-end">
              <div className="w-64 space-y-2">
                <div className="flex justify-between">
                  <span>Subtotal:</span>
                  <span>${calculateSubtotal().toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Tax ({formData.tax_rate}%):</span>
                  <span>${(calculateSubtotal() * (formData.tax_rate / 100)).toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-bold text-lg border-t pt-2">
                  <span>Total:</span>
                  <span>${calculateTotal().toFixed(2)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="flex gap-2">
          <button
            type="submit"
            className="btn btn-primary flex-1"
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                Creating...
              </>
            ) : (
              "Create Invoice"
            )}
          </button>
          <button
            type="button"
            onClick={handleCancel}
            className="btn btn-outline"
            disabled={loading}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}