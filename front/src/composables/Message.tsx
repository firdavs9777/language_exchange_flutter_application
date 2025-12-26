import { Alert } from "react-bootstrap";
import React, { FC } from "react";

interface MessageProps {
  variant?: string;
  children: React.ReactNode;
}

const Message: FC<MessageProps> = ({ variant = "info", children }) => {
  return (
    <div>
      <Alert variant={variant}>{children}</Alert>
    </div>
  );
};
Message.defaultProps = {
  variant: "info",
};
export default Message;
