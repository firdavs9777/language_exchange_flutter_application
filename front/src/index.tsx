import React from 'react';

import './index.css';
import App from './App';
import { createRoot } from 'react-dom/client';
import { BrowserRouter as Router, RouterProvider } from 'react-router-dom';
import { Provider } from 'react-redux';
import store from './store';
import './assets/styles/bootstrap.custom.css';
import router from './router/AppRouter';
const container = document.getElementById('root');
const root = createRoot(container!);
root.render(
    <React.StrictMode>
        <Provider store={store}>
            <RouterProvider router={router}>
            </RouterProvider>
        </Provider>
    </React.StrictMode>);
