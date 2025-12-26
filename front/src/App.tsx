import React from "react";
import "./App.scss";
import { I18nextProvider } from "react-i18next";
import i18n from "./utils/i18n";

import MainNavbar from "./components/navbar/MainNavbar";
import { Container } from "react-bootstrap";
import { Outlet } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import FooterMain from "./components/footer/FooterMain";


const App = () => {
  return (
    <I18nextProvider i18n={i18n}>
      <MainNavbar />
      <Container fluid>
        <Outlet />
      </Container>
      <FooterMain />
      <ToastContainer />
    </I18nextProvider>
  );
};

export default App;
