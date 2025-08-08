import React, { useState } from "react";
import { useApiRequest } from "../../hooks/useApiRequest";
import { visit } from "@hotwired/turbo";

interface PhoneInputProps {}

const PhoneInput: React.FC<PhoneInputProps> = () => {
  const [phoneNumber, setPhoneNumber] = useState("");
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const {
    loading,
    errors: apiErrors,
    makeRequest,
  } = useApiRequest({
    onSuccess: (data) => {
      visit(data.redirect_to || "/verification/edit");
    },
    onError: (message, errors) => {
      console.error("Verification failed:", message);
    },
  });

  const formatPhoneNumber = (value: string) => {
    const digits = value.replace(/\D/g, "");
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return `(${digits.slice(0, 3)}) ${digits.slice(3)}`;
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(
      6,
      10
    )}`;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Basic validation
    if (!phoneNumber) {
      setErrors({ phone_number: "Phone number is required" });
      return;
    }

    if (!/^\(\d{3}\) \d{3}-\d{4}$/.test(phoneNumber)) {
      setErrors({ phone_number: "Please enter a valid phone number" });
      return;
    }

    setErrors({});
    await makeRequest("POST", "/api/v1/verifications", {
      phone_number: phoneNumber,
    });
  };

  const handlePhoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const formatted = formatPhoneNumber(e.target.value);
    setPhoneNumber(formatted);
    if (errors.phone_number) {
      setErrors({});
    }
  };

  const getFieldError = (fieldName: string) => {
    return (
      errors[fieldName] || (apiErrors[fieldName] && apiErrors[fieldName][0])
    );
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="card w-full max-w-md bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title text-2xl font-bold text-center mb-6">
            Enter Your Phone Number
          </h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="label">
                <span className="label-text">Phone Number</span>
              </label>
              <input
                type="tel"
                value={phoneNumber}
                onChange={handlePhoneChange}
                placeholder="(555) 123-4567"
                className={`input input-bordered w-full ${
                  getFieldError("phone_number") ? "input-error" : ""
                }`}
                maxLength={14}
              />
              {getFieldError("phone_number") && (
                <span className="text-error text-sm">
                  {getFieldError("phone_number")}
                </span>
              )}
            </div>

            <button
              type="submit"
              className={`btn btn-primary w-full`}
              disabled={loading}
            >
              {loading ? "Sending..." : "Send Verification Code"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default PhoneInput;
