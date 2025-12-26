import React from "react";
import { Col, Row } from "react-bootstrap";

const InfoRow: React.FC<{ label: string; value: React.ReactNode }> = ({ label, value }) => {

  return (
  <Row className="mb-3">
    <Col xs={4} className="text-muted">
      {label}
    </Col>
    <Col xs={8}>{value}</Col>
  </Row>
);
}

export default InfoRow;