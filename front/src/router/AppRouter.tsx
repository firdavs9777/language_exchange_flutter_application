// import React from 'react';
// import {
//     Routes,
//     Route,
//   } from "react-router-dom";

// import NotFound from '../components/error/NotFound'
// import MainMoments from '../components/moments/MainMoments';
// import MainChat from '../components/chat/MainChat';
// import MainCommnity from '../components/community/MainCommunity';
// import AuthForm from '../components/auth/AuthForm';
// import HomeMain from '../components/home/HomeMain';

// const AppRouter: React.FC = () => {
//   return (
//     <Routes>
//           <Route path="/" Component={HomeMain} />
//       <Route path="/moments" Component={MainMoments} />
//       <Route path="/community" Component={MainCommnity} />
//       <Route path="/chat" Component={MainChat} />
//       <Route path="/auth" Component={AuthForm} />
//       <Route Component={NotFound} />
//     </Routes>
//   );
// };

// export default AppRouter;

import { createBrowserRouter, createRoutesFromElements, Route } from 'react-router-dom';
import App from '../App';
import HomeScreen from '../components/home/HomeMain';
import React from 'react';
import MainCommnity from '../components/community/MainCommunity';
import Login from '../components/auth/Login';
import MainChat from '../components/chat/MainChat';
import MainMoments from '../components/moments/MainMoments';

const AppRouter = createBrowserRouter(
  createRoutesFromElements(
    <Route path='/' element={<App />}>
     <Route index path='/' element={<HomeScreen/>}/> 
     <Route index path='/community' element={<MainCommnity/>}/> 
     <Route index path='/login' element={<Login/>}/>
     <Route index path='/chat' element={<MainChat/>}/>
     <Route index path='/moments' element={<MainMoments/>}/> 
    </Route>
  )
)

export default AppRouter;