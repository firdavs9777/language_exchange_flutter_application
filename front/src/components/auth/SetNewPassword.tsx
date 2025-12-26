import React from "react";
import { Button, Form, Container } from "react-bootstrap";
import { useResetPasswordUserMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";

interface SetNewPasswordProps {
  newPassword: string;
  confirmPassword: string;
  setNewPassword: (val: string) => void;
  setConfirmPassword: (val: string) => void;
  onSubmit: () => void;
}

const SetNewPassword: React.FC<SetNewPasswordProps> = ({
  newPassword,
  confirmPassword,
  setNewPassword,
  setConfirmPassword,
  onSubmit,
}) => {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword === confirmPassword) {
      onSubmit();
    } else {
      toast.error("Passwords do not match", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  return (
    <Container className="d-flex m-auto mt-4 justify-content-center align-items-center">
      <div
        className="card p-4 shadow-sm"
        style={{ maxWidth: "400px", width: "100%" }}
      >
        <h2 className="mb-4 text-center">Set New Password</h2>
        <Form onSubmit={handleSubmit}>
          <Form.Group controlId="newPassword">
            <Form.Label>New Password</Form.Label>
            <Form.Control
              type="password"
              placeholder="New Password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />
          </Form.Group>
          <Form.Group controlId="confirmPassword">
            <Form.Label>Confirm Password</Form.Label>
            <Form.Control
              type="password"
              placeholder="Confirm Password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
          </Form.Group>
          <Button
            variant="primary"
            type="submit"
            className="w-100 mt-2 text-white"
          >
            Reset Password
          </Button>
        </Form>
      </div>
    </Container>
  );
};

export default SetNewPassword;
