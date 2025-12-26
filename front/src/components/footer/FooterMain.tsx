import React from "react";
import { Container, Row, Col, Form, Button, InputGroup } from "react-bootstrap";
import "./FooterMain.scss";

const FooterMain: React.FC = () => {
  return (
    <footer className="footer-main py-4 py-md-5">
      <Container fluid="lg">
        <Row className="gy-4">
          {/* About Section */}
          <Col xs={12} sm={6} lg={3}>
            <h5 className="footer-heading mb-3">About Us</h5>
            <p className="text-muted small">
              BananaTalk is dedicated to helping you master new languages and
              connect with native speakers from around the world.
            </p>
          </Col>

          {/* Quick Links */}
          <Col xs={6} sm={6} lg={2}>
            <h5 className="footer-heading mb-3">Quick Links</h5>
            <ul className="list-unstyled footer-links small">
              <li className="mb-2">
                <a href="/" className="text-decoration-none">Home</a>
              </li>
              <li className="mb-2">
                <a href="/about" className="text-decoration-none">About</a>
              </li>
              <li className="mb-2">
                <a href="/services" className="text-decoration-none">Services</a>
              </li>
              <li className="mb-2">
                <a href="/pricing" className="text-decoration-none">Pricing</a>
              </li>
              <li className="mb-2">
                <a href="/contact" className="text-decoration-none">Contact</a>
              </li>
            </ul>
          </Col>

          {/* Contact Info */}
          <Col xs={6} sm={6} lg={3}>
            <h5 className="footer-heading mb-3">Contact Info</h5>
            <ul className="list-unstyled contact-info small text-muted">
              <li className="mb-2">
                <i className="bi bi-envelope me-2"></i>
                bananatalkmain@gmail.com
              </li>
              <li className="mb-2">
                <i className="bi bi-telephone me-2"></i>
                +821082773725
              </li>
              <li className="mb-2">
                <i className="bi bi-geo-alt me-2"></i>
                Seoul, South Korea, Gangnam-gu
              </li>
            </ul>
          </Col>

          {/* Social Media Links */}
          <Col xs={6} sm={6} lg={1}>
            <h5 className="footer-heading mb-3">Follow</h5>
            <div className="social-links d-flex flex-column small">
              <a
                href="https://facebook.com"
                target="_blank"
                rel="noopener noreferrer"
                className="mb-2 text-decoration-none"
              >
                <i className="bi bi-facebook me-2"></i>Facebook
              </a>
              <a
                href="https://twitter.com"
                target="_blank"
                rel="noopener noreferrer"
                className="mb-2 text-decoration-none"
              >
                <i className="bi bi-twitter me-2"></i>Twitter
              </a>
              <a
                href="https://instagram.com"
                target="_blank"
                rel="noopener noreferrer"
                className="mb-2 text-decoration-none"
              >
                <i className="bi bi-instagram me-2"></i>Instagram
              </a>
              <a
                href="https://linkedin.com"
                target="_blank"
                rel="noopener noreferrer"
                className="mb-2 text-decoration-none"
              >
                <i className="bi bi-linkedin me-2"></i>LinkedIn
              </a>
            </div>
          </Col>

          {/* Newsletter Sign-Up */}
          <Col xs={12} sm={6} lg={3}>
            <h5 className="footer-heading mb-3">Newsletter</h5>
            <p className="text-muted small">
              Subscribe to our newsletter for updates and offers.
            </p>
            <Form className="newsletter-form">
              <InputGroup size="sm">
                <Form.Control
                  type="email"
                  placeholder="Your email address"
                  required
                  className="border-end-0"
                />
                <Button type="submit" variant="outline-light">
                  <i className="bi bi-send"></i>
                </Button>
              </InputGroup>
            </Form>
          </Col>
        </Row>
      </Container>
      
      <div className="footer-bottom text-center mt-4 pt-3 border-top border-secondary border-opacity-25">
        <p className="mb-0 text-muted small">
          &copy; {new Date().getFullYear()} BananaTalk. All rights reserved.
        </p>
      </div>
    </footer>
  );
};

export default FooterMain;