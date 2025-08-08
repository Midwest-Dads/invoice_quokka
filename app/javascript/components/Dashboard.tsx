import React from "react";

interface DashboardProps {
  app_name: string;
}

const Dashboard: React.FC<DashboardProps> = ({ appName }) => {
  return (
    <React.StrictMode>
      <div className="p-6">
        <h1 className="text-4xl font-bold">Hello from {appName}</h1>
      </div>
    </React.StrictMode>
  );
};

export default Dashboard;
