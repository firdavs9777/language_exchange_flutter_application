import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useLoginUserMutation } from "../../store/slices/usersSlice";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { Eye, EyeOff, Mail, Lock, Loader2 } from "lucide-react";
import { FaGoogle } from "react-icons/fa";
import { useTranslation } from "react-i18next";
import { BASE_URL } from "../../constants";
import "./Login.scss";

const Login = () => {
  const { t } = useTranslation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPass, setShowPass] = useState(false);
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [loginUser, { isLoading }] = useLoginUserMutation();
  const { userInfo } = useSelector((state: any) => state.auth);
  const { search } = useLocation();
  const sp = new URLSearchParams(search);
  const redirect = sp.get("redirect") || "/";

  useEffect(() => {
    if (userInfo) {
      navigate(redirect);
    }
  }, [userInfo, redirect, navigate]);

  const submitHandler = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      const response = await loginUser({ email, password }).unwrap();
      dispatch(setCredentials({
        user: response.data || response.user,
        token: response.token,
        message: response.message || "Login successful",
      }));
      toast.success(t("authentication.login.successMessage"), {
        position: "top-right",
        autoClose: 2000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      navigate(redirect);
    } catch (error: any) {
      toast.error(t("authentication.login.invalidCredentialsError"), {
        position: "top-right",
        autoClose: 4000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleGoogleLogin = () => {
    const backendUrl = BASE_URL;
    sessionStorage.setItem("oauth_redirect", redirect);
    window.location.href = `${backendUrl}/api/v1/auth/google`;
  };

  return (
    <div className="auth-page">
      <div className="auth-container">
        {/* Left Side - Branding */}
        <div className="auth-branding">
          <div className="branding-content">
            <div className="brand-logo">🍌</div>
            <h1>Welcome Back!</h1>
            <p>Continue your language learning journey with BananaTalk</p>
            <div className="branding-features">
              <div className="feature-item">
                <span className="feature-icon">💬</span>
                <span>Chat with native speakers</span>
              </div>
              <div className="feature-item">
                <span className="feature-icon">🌍</span>
                <span>Learn 50+ languages</span>
              </div>
              <div className="feature-item">
                <span className="feature-icon">🎯</span>
                <span>Track your progress</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side - Form */}
        <div className="auth-form-container">
          <div className="auth-form-wrapper">
            <div className="form-header">
              <h2>{t("authentication.login.title")}</h2>
              <p>Enter your credentials to access your account</p>
            </div>

            {/* Google Login */}
            <button
              type="button"
              onClick={handleGoogleLogin}
              className="google-btn"
            >
              <FaGoogle size={20} />
              <span>{t("authentication.login.signInWithGoogle") || "Continue with Google"}</span>
            </button>

            {/* Divider */}
            <div className="divider">
              <span>{t("authentication.login.orText") || "or"}</span>
            </div>

            {/* Login Form */}
            <form onSubmit={submitHandler} className="auth-form">
              <div className="form-group">
                <label htmlFor="email">{t("authentication.login.emailLabel")}</label>
                <div className="input-wrapper">
                  <Mail className="input-icon" size={20} />
                  <input
                    type="email"
                    id="email"
                    placeholder={t("authentication.login.emailPlaceholder")}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <div className="label-row">
                  <label htmlFor="password">{t("authentication.login.passwordLabel")}</label>
                  <Link to="/forgot-password" className="forgot-link">
                    {t("authentication.login.forgotPassword")}
                  </Link>
                </div>
                <div className="input-wrapper">
                  <Lock className="input-icon" size={20} />
                  <input
                    type={showPass ? "text" : "password"}
                    id="password"
                    placeholder={t("authentication.login.passwordPlaceholder")}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                  <button
                    type="button"
                    className="toggle-password"
                    onClick={() => setShowPass(!showPass)}
                  >
                    {showPass ? <EyeOff size={20} /> : <Eye size={20} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="submit-btn"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="animate-spin" size={20} />
                    <span>{t("authentication.login.signingInButton")}</span>
                  </>
                ) : (
                  <span>{t("authentication.login.signInButton")}</span>
                )}
              </button>
            </form>

            <p className="auth-footer">
              {t("authentication.login.newUserText")}{" "}
              <Link to={redirect ? `/register?redirect=${redirect}` : `/register`}>
                {t("authentication.login.registerLink")}
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
