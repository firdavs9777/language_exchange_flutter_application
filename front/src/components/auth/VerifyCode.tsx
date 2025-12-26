import React from "react";
import { Button, Form, Container } from "react-bootstrap";
import { useVerifyCodeEmailMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";

interface VerifyCodeProps {
  code: string;
  email: string;
  setCode: (code: string) => void;
  onNext: () => void;
  onPrevious: () => void;
}

const VerifyCode: React.FC<VerifyCodeProps> = ({
  email,
  code,
  setCode,
  onNext,
  onPrevious,
}) => {
  const [verifyCodeEmail, { isLoading, error }] = useVerifyCodeEmailMutation(
    {}
  );
  interface SendCodeEmailResponse {
    success: boolean;
    statusCode: number;
    message: string;
  }
  const previousHandler = () => {
    onPrevious();
  };
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await verifyCodeEmail({ email, code }).unwrap();
      const typedResponse = response as SendCodeEmailResponse;
      if (typedResponse.success) {
        toast.success("Verification code successfully verified!", {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        onNext();
        setCode("");
      }
    } catch (error: any) {
      toast.error(`${error?.data?.error}`, {
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
        <h2 className="mb-4 text-center">Enter the verification code</h2>
        <Form onSubmit={handleSubmit}>
          <Form.Group controlId="verificationCode">
            <Form.Label>Verification Code</Form.Label>
            <Form.Control
              type="text"
              placeholder="Enter code"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              required
            />
          </Form.Group>
          <Button
            variant="warning"
            type="button"
            onClick={previousHandler}
            className="w-100 mt-2 text-white"
          >
            Previous
          </Button>
          <Button
            variant="primary"
            type="submit"
            className="w-100 mt-2 text-white"
          >
            Verify
          </Button>
        </Form>
      </div>
    </Container>
  );
};

export default VerifyCode;
