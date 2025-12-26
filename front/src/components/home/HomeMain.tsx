import React from "react";
import homeImg from "../../assets/3.png";
import "./HomeMain.scss";
import FooterMain from "../footer/FooterMain";
import { Container, Row, Col, Button, Form } from "react-bootstrap";

const HomeMain: React.FC = () => {
  return (
    <section className="home-main-section">
      {/* Hero Section */}
      <div className="hero-section py-5">
        <Container>
          <Row className="align-items-center">
            <Col md={6} className="text-center text-md-start">
              <h1 className="slogan">
                ONLINE <br />
                <span className="language">LANGUAGE</span> <br />
                <span className="learning">LEARNING</span>
              </h1>
              <p className="description">
                Expand your global network and language <br />
                skills with <span className="bananatalk">BananaTalk.</span>
              </p>
              <Button variant="primary" className="register-btn">
                Get Started
              </Button>
            </Col>
            <Col md={6} className="text-center">
              <img
                src={homeImg}
                alt="Language Learning"
                className="home-img img-fluid"
              />
            </Col>
          </Row>
        </Container>
      </div>

      {/* Features Section */}
      <div className="features-section py-5">
        <Container>
          <h2 className="features-heading text-center mb-4">
            Why Choose BananaTalk?
          </h2>
          <Row>
            <Col md={4} className="mb-4">
              <div className="feature text-center">
                <h3>Interactive Lessons</h3>
                <p>
                  Engage in interactive lessons designed to enhance your
                  language skills in a fun and effective way.
                </p>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="feature text-center">
                <h3>Native Speakers</h3>
                <p>
                  Practice with native speakers and improve your pronunciation
                  and fluency.
                </p>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="feature text-center">
                <h3>Flexible Scheduling</h3>
                <p>
                  Choose a schedule that fits your lifestyle and learn at your
                  own pace.
                </p>
              </div>
            </Col>
          </Row>
        </Container>
      </div>

      {/* How It Works Section */}
      <div className="how-it-works-section py-5">
        <Container>
          <h2 className="section-heading text-center mb-4">How It Works</h2>
          <Row>
            <Col md={4} className="mb-4">
              <div className="step text-center">
                <h3>Sign Up</h3>
                <p>Create an account and choose a plan that suits you.</p>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="step text-center">
                <h3>Choose a Tutor</h3>
                <p>
                  Browse through our list of tutors and select one that matches
                  your learning goals.
                </p>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="step text-center">
                <h3>Start Learning</h3>
                <p>
                  Schedule your sessions and start learning with our interactive
                  lessons.
                </p>
              </div>
            </Col>
          </Row>
        </Container>
      </div>

      {/* Pricing Section */}
      <div className="pricing-section py-5">
        <Container>
          <h2 className="section-heading text-center mb-4">Pricing Plans</h2>
          <Row>
            <Col md={4} className="mb-4">
              <div className="pricing-card text-center">
                <h3>Basic Plan</h3>
                <p>
                  Perfect for beginners. Includes access to basic lessons & and
                  chat features.
                </p>
                <span className="price">$19/month</span>
                <Button variant="outline-primary" className="pricing-button">
                  Choose Plan
                </Button>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="pricing-card text-center">
                <h3>Standard Plan</h3>
                <p>
                  Includes all features of the Basic Plan plus additional
                  interactive sessions an.
                </p>
                <span className="price">$39/month</span>
                <Button variant="outline-primary" className="pricing-button">
                  Choose Plan
                </Button>
              </div>
            </Col>
            <Col md={4} className="mb-4">
              <div className="pricing-card text-center">
                <h3>Premium Plan</h3>
                <p>
                  All features included, with unlimited access to all tutors and
                  advanced lessons.
                </p>
                <span className="price">$59/month</span>
                <Button variant="outline-primary" className="pricing-button">
                  Choose Plan
                </Button>
              </div>
            </Col>
          </Row>
        </Container>
      </div>
      <div className="contact-section py-5 card ">
        <Container>
          <h2 className="section-heading text-center mb-4">Get in Touch</h2>
          <p className="text-center">
            If you have any questions or need assistance, feel free to reach out
            to us!
          </p>
          <Form className="contact-form">
            <Form.Group controlId="formName">
              <Form.Label>Name</Form.Label>
              <Form.Control type="text" placeholder="Your name" required />
            </Form.Group>
            <Form.Group controlId="formEmail">
              <Form.Label>Email</Form.Label>
              <Form.Control type="email" placeholder="Your email" required />
            </Form.Group>
            <Form.Group controlId="formMessage">
              <Form.Label>Message</Form.Label>
              <Form.Control
                as="textarea"
                rows={4}
                placeholder="Your message"
                required
              />
            </Form.Group>
            <Button type="submit" variant="primary" className="contact-button">
              Send Message
            </Button>
          </Form>
        </Container>
      </div>

      {/* Footer */}
    </section>
  );
};

export default HomeMain;
