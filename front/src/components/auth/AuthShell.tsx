import React from 'react';

interface Props {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}

const AuthShell: React.FC<Props> = ({ title, subtitle, children }) => (
  <div className="min-h-screen flex bg-gradient-to-br from-teal-50 via-sky-50 to-purple-50">
    <div className="hidden lg:flex flex-1 items-center justify-center bg-gradient-to-br from-[#00BFA5] to-[#00A896] text-white p-12">
      <div className="max-w-md">
        <h1 className="text-4xl font-bold mb-4">BananaTalk</h1>
        <p className="text-white/90">Practice languages with native speakers worldwide.</p>
      </div>
    </div>
    <div className="flex-1 flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-white/80 backdrop-blur-xl rounded-2xl shadow-xl p-8">
        <h2 className="text-2xl font-semibold text-gray-900">{title}</h2>
        {subtitle && <p className="text-gray-500 mt-1 mb-6">{subtitle}</p>}
        <div className={subtitle ? '' : 'mt-6'}>{children}</div>
      </div>
    </div>
  </div>
);

export default AuthShell;
