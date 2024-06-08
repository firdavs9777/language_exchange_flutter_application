import React from 'react';
import { Container, Navbar, Nav } from 'react-bootstrap';
import { FaShoppingCart, FaUser, FaUsers, FaComment, FaGlobe } from 'react-icons/fa'
import logo from '../../assets/logo.png'
import './MainNavbar.css'
const MainNavbar = () => {
  return (
    <header>
      <Navbar  bg="dark" variant='dark' expand="md" collapseOnSelect>
        <Container>
          <Navbar.Brand href='/'><img src={logo} className='logo'/></Navbar.Brand>
          <Navbar.Toggle aria-controls='basic-navbar-nav' />
          <Navbar.Collapse id='basic-navbar-nav'>
            <Nav className='w-100 justify-content-center justify-content-md-end'>
              <Nav.Link href='/community' className='custom-nav-link'><FaUsers /> Community</Nav.Link>
              <Nav.Link href='/chat' className='custom-nav-link'><FaComment /> Chat</Nav.Link>
              <Nav.Link href='/moments' className='custom-nav-link'><FaGlobe /> Moments</Nav.Link>
              <Nav.Link href='/login' className='custom-nav-link'><FaUser /> Sign In</Nav.Link>
            </Nav>
          </Navbar.Collapse>
        </Container>
      </Navbar>
    </header>

  )
}
export default MainNavbar;

