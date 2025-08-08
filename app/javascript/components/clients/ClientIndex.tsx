import { visit } from "@hotwired/turbo";
import { Client } from "../../types/clients";

interface ClientIndexProps {
  clients: Client[];
}

export default function ClientIndex({ clients }: ClientIndexProps) {
  const handleNewClient = () => {
    visit("/clients/new");
  };

  const handleViewClient = (clientId: string) => {
    visit(`/clients/${clientId}`);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Clients</h1>
        <button
          onClick={handleNewClient}
          className="btn btn-primary"
        >
          New Client
        </button>
      </div>

      {/* Clients Table */}
      {clients.length === 0 ? (
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body text-center">
            <h2 className="card-title justify-center">No clients yet</h2>
            <p>Create your first client to get started with invoicing.</p>
            <div className="card-actions justify-center">
              <button onClick={handleNewClient} className="btn btn-primary">
                Create First Client
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
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {clients.map((client) => (
                    <tr key={client.id} className="hover">
                      <td className="font-semibold">{client.name}</td>
                      <td>{client.email}</td>
                      <td>{client.phone}</td>
                      <td>
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleViewClient(client.id)}
                            className="btn btn-sm btn-outline"
                          >
                            View
                          </button>
                          <button
                            onClick={() => visit(`/clients/${client.id}/edit`)}
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