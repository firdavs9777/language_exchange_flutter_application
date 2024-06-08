// import React, { useState, useEffect } from "react";
// import { Link , useLocation, useNavigate} from "react-router-dom";
// import FormContainer from "./FormContainer";
// import { Button, Col, Form, InputGroup, Row } from "react-bootstrap";
// import { FaEye, FaEyeSlash } from "react-icons/fa";
// import { AuthInfo, useLoginUserMutation } from "../../slices/usersSlice";
// import { UseSelector, useDispatch ,useSelector} from "react-redux";
// import Loader from "../Loader";
// import {  setCredentials } from "../../slices/authSlice";
// import {toast} from 'react-toastify';
import React from "react";

const Login = () => {

return (
  <div>
    Login
  </div>
)
  // const [email, setEmail] = useState("");
  // const [password, setPassword] = useState("");
  // const [showPass, setShowPass] = useState(false);

  // const dispatch = useDispatch();
  // const navigate = useNavigate();

  // const [loginUser, {isLoading}] = useLoginUserMutation();
  //  const {userInfo} = useSelector((state:any)=> state.auth);
  //  const {search} = useLocation();
  //  const sp = new URLSearchParams(search);
  //  const redirect = sp.get('redirect') || '/';

  //  useEffect(() => {
  //   if(userInfo)
  //     {
  //       navigate(redirect)
  //     }
  //  },[userInfo,redirect,userInfo]);

  //  const submitHandler = async (e: React.FormEvent<HTMLFormElement>) => {
  //   e.preventDefault();
  //   try {
  //     const userInfo = await loginUser({ email, password }).unwrap();
  //    const ActionPayload: Response | any = userInfo;
  //     dispatch(setCredentials({...ActionPayload}));
  //     navigate(redirect)
  //     // Handle successful login (e.g., redirect to dashboard, store token in localStorage, etc.)
  //   } catch (error: any) {
  //     toast(error.data.message || error.error) ;
  //     // Handle login error (e.g., show error message)
  //   }

  // };
  // const clickHandler = () => {
  //   setShowPass((prev) => !prev);
  // };
  // return (
  //   <FormContainer>
  //     <h1>Sign In</h1>
  //     <Form onSubmit={submitHandler}>
  //       <Form.Group controlId="email" className="my-4">
  //         <Form.Label>Email Address</Form.Label>
  //         <Form.Control
  //           type="email"
  //           placeholder="Enter email"
  //           value={email}
  //           onChange={(e) => setEmail(e.target.value)}
  //         ></Form.Control>
  //       </Form.Group>
  //       <Form.Group controlId="email" className="my-4">
  //         <Form.Label>Password</Form.Label>
  //         <InputGroup>
  //           <Form.Control
  //             type={showPass ? "text" : "password"}
  //             placeholder="Enter password"
  //             value={password}
  //             onChange={(e) => setPassword(e.target.value)}
  //           />
  //           <InputGroup.Text onClick={clickHandler}>
  //             {showPass ? <FaEyeSlash /> : <FaEye />}
  //           </InputGroup.Text>
  //         </InputGroup>
  //       </Form.Group>
  //       <Button disabled={isLoading} type='submit' variant='primary'>
  //         Sign In
  //       </Button>

  //       {isLoading && <Loader />}
  //       <Row className="py-3">
  //         <Col>
  //           New Customer? <Link to={ redirect ? `/register?redirect=${redirect}`: `/register`}>Register</Link>
  //         </Col>
  //       </Row>
  //     </Form>
  //   </FormContainer>
  // );
};

export default Login;
