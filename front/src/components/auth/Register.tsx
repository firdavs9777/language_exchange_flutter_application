import React, { useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import ISO6391 from "iso-639-1";

import {
  Button,
  Col,
  Form,
  Image,
  InputGroup,
  Row,
  Container,
} from "react-bootstrap";
import {
  FaEye,
  FaEyeSlash,
  FaPlus,
  FaTimes,
  FaArrowLeft,
  FaArrowRight,
  FaUserPlus,
} from "react-icons/fa";
import {
  useRegisterUserMutation,
  useUploadUserPhotoMutation,
  useSendCodeEmailMutation,
  useVerifyCodeEmailMutation,
  useRegisterCodeEmailMutation,
} from "../../store/slices/usersSlice";
import Loader from "../Loader";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";

export interface User {
  _id: string;
  name: string;
  gender: string;
  email: string;
  bio: string;
  birth_year: string;
  birth_month: string;
  birth_day: string;
  images: string[];
  followers: string[];
  following: string[];
  native_language: string;
  language_to_learn: string;
  createdAt: string;
}

export interface responseType {
  success: boolean;
  token: string;
  option: {
    expires: string;
    httpOnly: boolean;
  };
  user: User;
}

interface VerifyCodeResponse {
  success: boolean;
  statusCode: number;
  message: string;
}

const Register = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [name, setName] = useState("");
  const [bio, setBio] = useState("");
  const [selectedGender, setSelectedGender] = useState("");
  const [nativeLanguage, setNativeLanguage] = useState("");
  const [languageToLearn, setLanguageToLearn] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [verificationCode, setVerificationCode] = useState("");
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [showPass, setShowPass] = useState(false);
  const [showPassTwo, setShowPassTwo] = useState(false);
  const [step, setStep] = useState(1); // State to track current step
  const [isCodeVerified, setIsCodeVerified] = useState(false);
  const navigate = useNavigate();
  const { t } = useTranslation();

  const [registerUser, { isLoading: isRegistering }] =
    useRegisterUserMutation();
  const [uploadUserPhoto, { isLoading: isUploading }] =
    useUploadUserPhotoMutation();
  const [sendCodeEmail, { isLoading: isSendingCode }] =
    useRegisterCodeEmailMutation();
  const [verifyCode, { isLoading: isVerifying }] = useVerifyCodeEmailMutation();

  const fileInputRef = useRef<HTMLInputElement>(null);

  const { search } = useLocation();
  const sp = new URLSearchParams(search);
  const redirect = sp.get("redirect") || "/";

  // First step handler (collecting name and email)
  const handleFirstStep = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (password !== confirmPassword) {
      toast.error("Passwords do not match", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }
    setStep(2); // Move to the second step
  };

  // Second step handler
  const handleSecondStep = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // Send verification code to the email
    handleSendVerificationCode();
  };

  interface SendCodeEmailResponse {
    success: boolean;
    message: string;
    expiresIn?: string;
  }

  const handleSendVerificationCode = async (): Promise<void> => {
    try {
      const response = (await sendCodeEmail({
        email,
      }).unwrap()) as SendCodeEmailResponse;

      if (response.success) {
        toast.success("Verification code sent successfully!", {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        setStep(3);
      }
    } catch (error: any) {
      toast.error(error?.data?.message || "Failed to send verification code", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      console.error("Error sending verification code:", error);
    }
  };

  // Handle code verification only
  const handleVerifyCode = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      // First verify the code
      const verificationResponse = (await verifyCode({
        email,
        code: verificationCode,
      }).unwrap()) as VerifyCodeResponse;

      if (verificationResponse.success) {
        setIsCodeVerified(true);
        toast.success("Email verified successfully!", {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
      }
    } catch (error: any) {
      toast.error(`${error?.data?.error || "Invalid verification code"}`, {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  // Handle the final registration after verification
  const handleFinalRegistration = async () => {
    if (!isCodeVerified) {
      toast.error("Please verify your email first", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }

    const [year, month, day] = birthDate.split("-");

    // Prepare formData for submission
    const formData = new FormData();
    formData.append("name", name);
    formData.append("email", email);
    formData.append("password", password);
    formData.append("bio", bio);
    formData.append("gender", selectedGender);
    formData.append("native_language", nativeLanguage);
    formData.append("language_to_learn", languageToLearn);
    formData.append("birth_day", day);
    formData.append("birth_month", month);
    formData.append("birth_year", year);

    try {
      // Send formData to your server using the registerUser mutation
      const response = await registerUser(formData).unwrap();
      const user_id = response as responseType;

      // If images are selected, upload them
      if (selectedImages && selectedImages.length > 0) {
        const uploadFormData = new FormData();
        selectedImages.forEach((file) => {
          uploadFormData.append("file", file); // Correctly append each file
        });
        await uploadUserPhoto({
          userId: user_id.user._id, // Use `_id` from the response
          imageFiles: uploadFormData, // Pass FormData directly
        }).unwrap();
      }

      toast.success("Registration successful!", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      navigate("/login"); // Redirect to login page
    } catch (error: any) {
      toast.error(`${error?.data?.error || "Error during registration"}`, {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  // Handle file selection for image upload
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    setSelectedImages((prevImages) => [...prevImages, ...files]);

    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setImagePreviews((prevPreviews) => [...prevPreviews, ...newPreviews]);
  };

  const handleRemoveImage = (index: number) => {
    setSelectedImages((prevImages) => prevImages.filter((_, i) => i !== index));
    setImagePreviews((prevPreviews) =>
      prevPreviews.filter((_, i) => i !== index)
    );
  };

  const handleAddMoreImages = () => {
    fileInputRef.current?.click();
  };

  const clickHandler = () => {
    setShowPass((prev) => !prev);
  };

  const clickHandlerConfirm = () => {
    setShowPassTwo((prev) => !prev);
  };

  const languageOptions = ISO6391.getAllCodes().map((code) => ({
    value: code,
    label: ISO6391.getName(code),
  }));

  // Clean up object URLs to avoid memory leaks
  useEffect(() => {
    return () => {
      imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    };
  }, [imagePreviews]);

  // Progress bar calculation
  const calculateProgress = () => {
    if (step === 1) return 33;
    if (step === 2) return 66;
    return 100;
  };

  // Render different forms based on the current step
  return (
    <Container className="py-5">
      <Row className="justify-content-center">
        <Col md={8} lg={6}>
          <div className="bg-white rounded-lg shadow-lg p-4">
            {/* Progress Bar */}
            <div className="mb-4">
              <div className="progress" style={{ height: "8px" }}>
                <div
                  className="progress-bar bg-primary"
                  role="progressbar"
                  style={{ width: `${calculateProgress()}%` }}
                  aria-valuenow={calculateProgress()}
                  aria-valuemin={0}
                  aria-valuemax={100}
                ></div>
              </div>
              <div className="d-flex justify-content-between mt-2">
                <span
                  className={`step-indicator ${
                    step >= 1 ? "text-primary fw-bold" : ""
                  }`}
                >
                  {" "}
                  {t("authentication.progressBar.account")}
                </span>
                <span
                  className={`step-indicator ${
                    step >= 2 ? "text-primary fw-bold" : ""
                  }`}
                >
                  {t("authentication.progressBar.profile")}
                </span>
                <span
                  className={`step-indicator ${
                    step >= 3 ? "text-primary fw-bold" : ""
                  }`}
                >
                  {t("authentication.progressBar.verify")}
                </span>
              </div>
            </div>

            {step === 1 ? (
              <Form onSubmit={handleFirstStep}>
                <h2 className="text-center mb-4">
                  {t("authentication.account.title")}
                </h2>

                <Form.Group controlId="name" className="mb-3">
                  <Form.Label className="fw-medium">
                    {t("authentication.account.name")}{" "}
                    <span className="text-danger">*</span>
                  </Form.Label>
                  <Form.Control
                    type="text"
                    placeholder={t("authentication.account.name")}
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    className="py-2"
                  />
                </Form.Group>

                <Form.Group controlId="email" className="mb-3">
                  <Form.Label className="fw-medium">
                    {t("authentication.account.email")}
                    <span className="text-danger">*</span>
                  </Form.Label>
                  <Form.Control
                    type="email"
                    placeholder={t("authentication.account.email")}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="py-2"
                  />
                </Form.Group>

                <Form.Group controlId="password" className="mb-3">
                  <Form.Label className="fw-medium">
                    {t("authentication.account.password")}{" "}
                    <span className="text-danger">*</span>
                  </Form.Label>
                  <InputGroup>
                    <Form.Control
                      type={showPass ? "text" : "password"}
                      placeholder={t("authentication.account.password")}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      className="py-2"
                    />
                    <Button
                      variant="outline-secondary"
                      onClick={clickHandler}
                      className="d-flex align-items-center"
                    >
                      {showPass ? <FaEyeSlash /> : <FaEye />}
                    </Button>
                  </InputGroup>
                  <Form.Text className="text-muted">
                    {t("authentication.account.passwordRequirement")}
                  </Form.Text>
                </Form.Group>

                <Form.Group controlId="confirmPassword" className="mb-4">
                  <Form.Label className="fw-medium">
                    {t("authentication.account.confirmPassword")}{" "}
                    <span className="text-danger">*</span>
                  </Form.Label>
                  <InputGroup>
                    <Form.Control
                      type={showPassTwo ? "text" : "password"}
                      placeholder={t("authentication.account.confirmPassword")}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      required
                      className="py-2"
                    />
                    <Button
                      variant="outline-secondary"
                      onClick={clickHandlerConfirm}
                      className="d-flex align-items-center"
                    >
                      {showPassTwo ? <FaEyeSlash /> : <FaEye />}
                    </Button>
                  </InputGroup>
                </Form.Group>

                <Button
                  type="submit"
                  variant="primary"
                  className="w-100 py-2 mb-3 d-flex align-items-center justify-content-center"
                >
                  {t("authentication.account.continue")}{" "}
                  <FaArrowRight className="ms-2" />
                </Button>

                <div className="text-center mt-3">
                  {t("authentication.account.alreadyHaveAccount")}{" "}
                  <Link
                    to={redirect ? `/login?redirect=${redirect}` : `/login`}
                    className="text-decoration-none"
                  >
                    {t("authentication.account.login")}
                  </Link>
                </div>
              </Form>
            ) : step === 2 ? (
              <Form onSubmit={handleSecondStep}>
                <h2 className="text-center mb-4">
                  {t("authentication.profile.title")}
                </h2>

                <Form.Group controlId="bio" className="mb-3">
                  <Form.Label className="fw-medium">
                    {t("authentication.profile.bio")}
                  </Form.Label>
                  <Form.Control
                    as="textarea"
                    rows={2}
                    placeholder={t("authentication.profile.bioPlaceholder")}
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    className="py-2"
                  />
                </Form.Group>

                <Row>
                  <Col md={6}>
                    <Form.Group controlId="gender" className="mb-3">
                      <Form.Label className="fw-medium">
                        {t("authentication.profile.gender")}{" "}
                        <span className="text-danger">*</span>
                      </Form.Label>
                      <Form.Select
                        value={selectedGender}
                        onChange={(e) => setSelectedGender(e.target.value)}
                        required
                        className="py-2"
                      >
                        <option value="">Select Gender</option>
                        <option value="male">Male</option>
                        <option value="female">Female</option>
                        <option value="other">Other</option>
                      </Form.Select>
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group controlId="birthDate" className="mb-3">
                      <Form.Label className="fw-medium">
                        Birth Date <span className="text-danger">*</span>
                      </Form.Label>
                      <Form.Control
                        type="date"
                        value={birthDate}
                        onChange={(e) => setBirthDate(e.target.value)}
                        required
                        className="py-2"
                      />
                    </Form.Group>
                  </Col>
                </Row>

                <Row>
                  <Col md={6}>
                    <Form.Group controlId="nativeLanguage" className="mb-3">
                      <Form.Label className="fw-medium">
                        Native Language <span className="text-danger">*</span>
                      </Form.Label>
                      <Form.Select
                        value={nativeLanguage}
                        onChange={(e) => setNativeLanguage(e.target.value)}
                        required
                        className="py-2"
                      >
                        <option value="">Select Language</option>
                        {languageOptions.map((lang) => (
                          <option key={lang.value} value={lang.label}>
                            {lang.label}
                          </option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group controlId="languageToLearn" className="mb-3">
                      <Form.Label className="fw-medium">
                        Language to Learn <span className="text-danger">*</span>
                      </Form.Label>
                      <Form.Select
                        value={languageToLearn}
                        onChange={(e) => setLanguageToLearn(e.target.value)}
                        required
                        className="py-2"
                      >
                        <option value="">Select Language</option>
                        {languageOptions.map((lang) => (
                          <option key={lang.value} value={lang.label}>
                            {lang.label}
                          </option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                  </Col>
                </Row>

                <Form.Group controlId="imageUpload" className="mb-4">
                  <Form.Label className="fw-medium">
                    Profile Images <span className="text-danger">*</span>
                  </Form.Label>

                  {imagePreviews.length > 0 ? (
                    <div className="mb-3">
                      <Row className="g-2">
                        {imagePreviews.map((preview, index) => (
                          <Col
                            key={index}
                            xs={4}
                            sm={3}
                            className="position-relative"
                          >
                            <div
                              className="image-container rounded overflow-hidden"
                              style={{ height: "100px" }}
                            >
                              <Image
                                src={preview}
                                style={{
                                  objectFit: "cover",
                                  width: "100%",
                                  height: "100%",
                                }}
                              />
                              <Button
                                variant="danger"
                                size="sm"
                                onClick={() => handleRemoveImage(index)}
                                className="position-absolute top-0 end-0 rounded-circle p-1"
                                style={{ width: "28px", height: "28px" }}
                              >
                                <FaTimes />
                              </Button>
                            </div>
                          </Col>
                        ))}
                        {selectedImages.length > 0 && (
                          <Col xs={4} sm={3}>
                            <Button
                              variant="light"
                              onClick={handleAddMoreImages}
                              className="add-image-btn border h-100 w-100 d-flex align-items-center justify-content-center"
                              style={{ height: "100px" }}
                            >
                              <FaPlus size={24} />
                            </Button>
                          </Col>
                        )}
                      </Row>
                    </div>
                  ) : (
                    <div className="upload-container border rounded p-4 text-center mb-3">
                      <FaPlus size={24} className="mb-2 text-muted" />
                      <p className="mb-2">Click to upload profile images</p>
                      <Form.Control
                        type="file"
                        multiple
                        accept="image/*"
                        onChange={handleImageUpload}
                        required
                        className="d-none"
                        id="formFileUpload"
                      />
                      <label
                        htmlFor="formFileUpload"
                        className="btn btn-outline-primary"
                      >
                        Select Images
                      </label>
                    </div>
                  )}

                  <Form.Control
                    type="file"
                    multiple
                    onChange={handleImageUpload}
                    ref={fileInputRef}
                    style={{ display: "none" }}
                  />
                </Form.Group>

                <Row className="mb-3">
                  <Col>
                    <Button
                      type="button"
                      variant="outline-secondary"
                      className="w-100 py-2 d-flex align-items-center justify-content-center"
                      onClick={() => setStep(1)}
                    >
                      <FaArrowLeft className="me-2" /> Back
                    </Button>
                  </Col>
                  <Col>
                    <Button
                      disabled={isSendingCode}
                      type="submit"
                      variant="primary"
                      className="w-100 py-2 d-flex align-items-center justify-content-center"
                    >
                      {isSendingCode ? (
                        <>Processing...</>
                      ) : (
                        <>
                          Continue <FaArrowRight className="ms-2" />
                        </>
                      )}
                    </Button>
                  </Col>
                </Row>

                {isSendingCode && <Loader />}
              </Form>
            ) : (
              // Step 3: Email Verification
              <div>
                <h2 className="text-center mb-4">Email Verification</h2>
                <div className="text-center mb-4">
                  <div className="verification-icon bg-light p-3 rounded-circle d-inline-flex mb-3">
                    <FaUserPlus size={32} className="text-primary" />
                  </div>
                  <p>
                    We've sent a verification code to your email:
                    <br />
                    <strong>{email}</strong>
                  </p>
                </div>

                {!isCodeVerified ? (
                  <Form onSubmit={handleVerifyCode}>
                    <Form.Group controlId="verificationCode" className="mb-4">
                      <Form.Label className="fw-medium">
                        Verification Code
                      </Form.Label>
                      <Form.Control
                        type="text"
                        placeholder="Enter the 6-digit code"
                        value={verificationCode}
                        onChange={(e) => setVerificationCode(e.target.value)}
                        required
                        className="py-2 text-center form-control-lg"
                      />
                    </Form.Group>

                    <Button
                      type="submit"
                      variant="primary"
                      className="w-100 py-2 mb-3"
                      disabled={isVerifying}
                    >
                      {isVerifying ? "Verifying..." : "Verify Email"}
                    </Button>

                    <div className="text-center mb-4">
                      <Button
                        variant="link"
                        onClick={handleSendVerificationCode}
                        disabled={isSendingCode}
                        className="text-decoration-none"
                      >
                        {isSendingCode
                          ? "Sending..."
                          : "Resend verification code"}
                      </Button>
                    </div>

                    <Button
                      type="button"
                      variant="outline-secondary"
                      className="w-100 py-2 d-flex align-items-center justify-content-center"
                      onClick={() => setStep(2)}
                    >
                      <FaArrowLeft className="me-2" /> Back to Profile
                    </Button>

                    {isVerifying && <Loader />}
                  </Form>
                ) : (
                  <div>
                    <div className="alert alert-success">
                      <p className="mb-0 text-center">
                        <strong>Email verified successfully!</strong>
                        <br />
                        Complete your registration by clicking the button below.
                      </p>
                    </div>

                    <Button
                      onClick={handleFinalRegistration}
                      variant="success"
                      className="w-100 py-2 mb-3"
                      disabled={isRegistering || isUploading}
                    >
                      {isRegistering || isUploading
                        ? "Processing..."
                        : "Complete Registration"}
                    </Button>

                    {(isRegistering || isUploading) && <Loader />}
                  </div>
                )}
              </div>
            )}
          </div>
        </Col>
      </Row>

      {/* <style jsx>{`
        .step-indicator {
          font-size: 0.875rem;
          color: #6c757d;
        }
      `}</style> */}
    </Container>
  );
};

export default Register;
