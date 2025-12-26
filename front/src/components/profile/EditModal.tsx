import React from "react";
import { Modal, Button} from "react-bootstrap";

interface EditModalProps {
  show: boolean;
  onHide: () => void;
  onSave: () => void;
  title: string;
  children: React.ReactNode;
}

const EditModal: React.FC<EditModalProps> = ({
  show,
  onHide,
  onSave,
  title,
  children,
}) => {
  return (
    <Modal show={show} onHide={onHide} centered>
      <Modal.Header closeButton>
        <Modal.Title>{title}</Modal.Title>
      </Modal.Header>
      <Modal.Body>{children}</Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Close
        </Button>
        <Button variant="primary" onClick={onSave}>
          Save Changes
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default EditModal;
