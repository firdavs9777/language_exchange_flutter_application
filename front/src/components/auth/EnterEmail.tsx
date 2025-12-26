import React from "react";
import { Button, Form, Container } from "react-bootstrap";
import { useSendCodeEmailMutation } from "../../store/slices/usersSlice";

import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
interface EnterEmailProps {
  email: string;
  setEmail: (email: string) => void;
  onNext: () => void;
}
interface SendCodeEmailResponse {
  success: boolean;
  statusCode: number;
  message: string; // Adjust based on actual response
}
const EnterEmail: React.FC<EnterEmailProps> = ({ email, setEmail, onNext }) => {
  const [sendCodeEmail, { isLoading }] = useSendCodeEmailMutation({});
  const {t} = useTranslation()
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await sendCodeEmail({ email }).unwrap();

      const typedResponse = response as SendCodeEmailResponse;

      if (typedResponse.success) {
        toast.success(t("authentication.enterEmail.successMessage"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        onNext();
      }
    } catch (error: any) {
      console.log(error);
      toast.error(`${error?.data?.error}`, {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };


  return (
    <Container
      className="d-flex mt-2 justify-content-center align-items-center"
      style={{ minHeight: "100%" }}
    >
      <div
        className="card p-4 shadow-sm"
        style={{ maxWidth: "400px", width: "100%" }}
      >
        <h2 className="mb-4 text-center">{ t("authentication.enterEmail.title")}</h2>
        <Form onSubmit={handleSubmit}>
          <Form.Group controlId="email">
            <Form.Label>{ t("authentication.enterEmail.emailLabel")}</Form.Label>
            <Form.Control
              type="email"
              placeholder={ t("authentication.enterEmail.emailLabel")}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Form.Group>
          <Button
            variant="success"
            type="submit"
            className="w-100 mt-2 text-white"
            disabled={isLoading}
          >
            {isLoading ? t("authentication.enterEmail.sendingButton") : t("authentication.enterEmail.sendButton")} 
          </Button>
        </Form>
      </div>
    </Container>
  );
};

export default EnterEmail;
