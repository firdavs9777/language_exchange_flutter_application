import React, { FC } from "react";
import { Container, Row, Col } from "react-bootstrap";

interface FormProps {
  children: React.ReactNode;
}
const FormContainer: FC<FormProps> = ({ children }) => {
  return (
    <Container>
      <Row className="d-flex  justify-content-md-center">
        <Col xs={12} md={6}>
          {children}
        </Col>
      </Row>
    </Container>
  );
};
export default FormContainer;
