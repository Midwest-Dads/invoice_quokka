import { useState } from "react";
import { visit } from "@hotwired/turbo";
import { useApiRequest } from "../../hooks/useApiRequest";
import { Client } from "../../types/clients";

interface ClientCreateProps {
  client: Client;
}

export default function ClientCreate({ client }: ClientCreateProps) {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    address: "",
    phone: "",
  });

  const { loading, makeRequest, getFieldError } = useApiRequest({
    onSuccess: (data) => {
      visit(`/clients/${data.id}`);
    },
    onError: (error) => {
      console.error("Failed to create client:", error);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    await makeRequest("POST", "/api/v1/clients", {
      client: formData,
    });
  };

  const handleCancel = () => {
    visit("/clients");
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Create New Client</h1>
        <button
          onClick={handleCancel}
          className="btn btn-outline"
        >
          Cancel
        </button>
      </div>

      {/* Form */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Name field */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Name</span>
              </label>
              <input
                type="text"
                className={`input input-bordered ${getFieldError('name') ? 'input-error' : ''}`}
                placeholder="Enter client name"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  name: e.target.value
                }))}
              />
              {getFieldError('name') && (
                <label className="label">
                  <span className="label-text-alt text-error">{getFieldError('name')}</span>
                </label>
              )}
            </div>

            {/* Email field */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Email</span>
              </label>
              <input
                type="email"
                className={`input input-bordered ${getFieldError('email') ? 'input-error' : ''}`}
                placeholder="Enter email address"
                value={formData.email}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  email: e.target.value
                }))}
              />
              {getFieldError('email') && (
                <label className="label">
                  <span className="label-text-alt text-error">{getFieldError('email')}</span>
                </label>
              )}
            </div>

            {/* Phone field */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Phone</span>
              </label>
              <input
                type="text"
                className={`input input-bordered ${getFieldError('phone') ? 'input-error' : ''}`}
                placeholder="Enter phone number"
                value={formData.phone}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  phone: e.target.value
                }))}
              />
              {getFieldError('phone') && (
                <label className="label">
                  <span className="label-text-alt text-error">{getFieldError('phone')}</span>
                </label>
              )}
            </div>

            {/* Address field */}
            <div className="form-control">
              <label className="label">
                <span className="label-text">Address</span>
              </label>
              <textarea
                className={`textarea textarea-bordered ${getFieldError('address') ? 'textarea-error' : ''}`}
                placeholder="Enter billing address"
                value={formData.address}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  address: e.target.value
                }))}
                rows={4}
              />
              {getFieldError('address') && (
                <label className="label">
                  <span className="label-text-alt text-error">{getFieldError('address')}</span>
                </label>
              )}
            </div>

            {/* Submit buttons */}
            <div className="form-control mt-6">
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
                    "Create Client"
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
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}