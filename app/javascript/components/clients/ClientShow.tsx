import { visit } from "@hotwired/turbo";
import { Client } from "../../types/clients";

interface ClientShowProps {
  client: Client;
}

export default function ClientShow({ client }: ClientShowProps) {
  const handleEdit = () => {
    visit(`/clients/${client.id}/edit`);
  };

  const handleBack = () => {
    visit("/clients");
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">{client.name}</h1>
        <div className="flex gap-2">
          <button
            onClick={handleEdit}
            className="btn btn-primary"
          >
            Edit Client
          </button>
          <button
            onClick={handleBack}
            className="btn btn-outline"
          >
            Back to Clients
          </button>
        </div>
      </div>

      {/* Client Details */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Client Information</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="label">
                <span className="label-text font-semibold">Name</span>
              </label>
              <p className="text-lg">{client.name}</p>
            </div>

            <div>
              <label className="label">
                <span className="label-text font-semibold">Email</span>
              </label>
              <p className="text-lg">
                <a href={`mailto:${client.email}`} className="link link-primary">
                  {client.email}
                </a>
              </p>
            </div>

            <div>
              <label className="label">
                <span className="label-text font-semibold">Phone</span>
              </label>
              <p className="text-lg">
                {client.phone ? (
                  <a href={`tel:${client.phone}`} className="link link-primary">
                    {client.phone}
                  </a>
                ) : (
                  <span className="text-gray-500">Not provided</span>
                )}
              </p>
            </div>

            <div className="md:col-span-2">
              <label className="label">
                <span className="label-text font-semibold">Address</span>
              </label>
              <p className="text-lg whitespace-pre-line">
                {client.address || (
                  <span className="text-gray-500">Not provided</span>
                )}
              </p>
            </div>
          </div>

          <div className="divider"></div>

          <div className="flex justify-between text-sm text-gray-500">
            <span>Created: {new Date(client.createdAt).toLocaleDateString()}</span>
            <span>Updated: {new Date(client.updatedAt).toLocaleDateString()}</span>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Quick Actions</h2>
          
          <div className="flex gap-2">
            <button
              onClick={() => visit(`/invoices/new?client_id=${client.id}`)}
              className="btn btn-success"
            >
              Create Invoice
            </button>
            <button
              onClick={() => visit(`/invoices?client_id=${client.id}`)}
              className="btn btn-outline"
            >
              View Invoices
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}