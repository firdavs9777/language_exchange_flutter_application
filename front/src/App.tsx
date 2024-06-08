import React from 'react';
import './App.scss';

import MainNavbar from './components/navbar/MainNavbar';
import AppRouter from './router/AppRouter';
import { Container } from 'react-bootstrap';
import { Outlet } from 'react-router-dom';
// import TodoList from './components/TodoList';

const App = () => {
  return (
   <>
    <MainNavbar/>
<main>
<Container>
    <Outlet/>
  </Container>
</main>
   </>
    );
};

export default App;
