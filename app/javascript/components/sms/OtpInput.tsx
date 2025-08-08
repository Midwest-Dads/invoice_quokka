import React, { useState } from "react";
import { useApiRequest } from "../../hooks/useApiRequest";
import { visit } from "@hotwired/turbo";

interface OtpInputProps {
  phoneNumber: string;
}

interface OtpFormData {
  code: string;
}

const OtpInput: React.FC<OtpInputProps> = ({ phoneNumber }) => {
  const [code, setCode] = useState("");
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const {
    loading,
    errors: apiErrors,
    makeRequest,
  } = useApiRequest({
    onSuccess: (data) => {
      visit(data.redirect_to || "/");
    },
    onError: (message, errors) => {
      console.error("Verification failed:", message);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Basic validation
    if (!code || code.length !== 6) {
      setErrors({ code: "Please enter a 6-digit code" });
      return;
    }

    setErrors({});
    await makeRequest("PATCH", "/api/v1/verification", { code });
  };

  const handleCodeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/\D/g, "").slice(0, 6);
    setCode(value);
    if (errors.code) {
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
          <h2 className="card-title text-2xl font-bold text-center mb-2">
            Enter Verification Code
          </h2>
          <p className="text-center text-gray-600 mb-6">
            We sent a code to {phoneNumber}
          </p>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="flex justify-center">
              <input
                type="text"
                value={code}
                onChange={handleCodeChange}
                placeholder="123456"
                className={`input input-bordered w-40 h-16 text-center text-2xl font-mono ${
                  getFieldError("code") ? "input-error" : ""
                }`}
                maxLength={6}
                autoFocus
              />
            </div>

            {getFieldError("code") && (
              <p className="text-error text-sm text-center">
                {getFieldError("code")}
              </p>
            )}

            <button
              type="submit"
              className={`btn btn-primary w-full`}
              disabled={loading || code.length !== 6}
            >
              {loading ? "Verifying..." : "Verify Code"}
            </button>
          </form>

          <div className="text-center mt-4">
            <button
              onClick={() => visit("/verification/new")}
              className="link link-primary"
            >
              Use a different phone number
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OtpInput;
