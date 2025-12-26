import React from "react";
import { Link } from "react-router-dom";
import "./PrivacyPolicy.css"; // Reusing the same CSS for consistent styling

const DataDeletion = () => {
  return (
    <>
      <div className="privacy-policy-container">
        <div className="privacy-policy-content">
          <h1>Data Deletion Instructions</h1>
          <p className="effective-date">
            <strong>Last Updated:</strong> November 18, 2025
          </p>

          <section className="policy-section">
            <h2>Account and Data Deletion</h2>
            <p>
              At BananaTalk, we respect your right to control your personal
              data. If you wish to delete your account and all associated data,
              you have two options:
            </p>
          </section>

          <section className="policy-section">
            <h2>Option 1: Delete Your Account In-App</h2>
            <p>
              You can delete your account directly from the BananaTalk mobile
              app:
            </p>
            <ol>
              <li>Open the BananaTalk app</li>
              <li>
                Go to <strong>Settings</strong>
              </li>
              <li>
                Tap on <strong>Account Settings</strong>
              </li>
              <li>
                Select <strong>Delete Account</strong>
              </li>
              <li>Confirm your decision</li>
            </ol>
            <p>
              Once you confirm, your account and all associated data will be
              permanently deleted within 30 days.
            </p>
          </section>

          <section className="policy-section">
            <h2>Option 2: Request Deletion via Email</h2>
            <p>
              If you're unable to access the app or prefer to request deletion
              via email, please follow these steps:
            </p>
            <ol>
              <li>
                Send an email to:{" "}
                <a href="mailto:banatalkmain@gmail.com?subject=Delete%20My%20Account">
                  banatalkmain@gmail.com
                </a>
              </li>
              <li>
                Use the subject line: <strong>"Delete My Account"</strong>
              </li>
              <li>Include your registered email address in the email body</li>
              <li>
                Optionally, include your username to help us locate your account
                faster
              </li>
            </ol>
            <p>
              We will process your request within <strong>30 days</strong> and
              send you a confirmation email once your data has been deleted.
            </p>
          </section>

          <section className="policy-section">
            <h2>What Data Will Be Deleted?</h2>
            <p>
              When you delete your account, the following data will be
              permanently removed:
            </p>
            <ul>
              <li>Your profile information (name, email, bio, photos)</li>
              <li>All moments (posts) you've created</li>
              <li>All stories you've posted</li>
              <li>Your chat history and messages</li>
              <li>Your followers and following lists</li>
              <li>Comments and likes you've made</li>
              <li>Location data and device information</li>
              <li>Any other personal data associated with your account</li>
            </ul>
          </section>

          <section className="policy-section">
            <h2>Important Notes</h2>
            <div className="contact-info">
              <p>
                <strong>⚠️ This action is permanent:</strong> Once your account
                is deleted, you cannot recover your data or reactivate your
                account.
              </p>
              <p>
                <strong>📱 Backup your data:</strong> Before deleting your
                account, make sure to download any content or data you wish to
                keep.
              </p>
              <p>
                <strong>⏰ Processing time:</strong> It may take up to 30 days
                to fully delete your data from our systems and backups.
              </p>
              <p>
                <strong>🔒 Legal retention:</strong> Some data may be retained
                if required by law or for legitimate business purposes (e.g.,
                fraud prevention, legal compliance).
              </p>
            </div>
          </section>

          <section className="policy-section">
            <h2>Data Retention After Deletion</h2>
            <p>
              After you delete your account, we will remove your personal data
              from our active systems. However, certain information may be
              retained:
            </p>
            <ul>
              <li>
                For up to 90 days in backup systems (for disaster recovery
                purposes)
              </li>
              <li>
                As required by law (e.g., tax records, transaction history)
              </li>
              <li>
                For legitimate business purposes (e.g., preventing fraud,
                resolving disputes)
              </li>
            </ul>
            <p>
              This retained data will be kept secure and will not be used for
              any other purposes.
            </p>
          </section>

          <section className="policy-section">
            <h2>Questions or Concerns?</h2>
            <p>
              If you have any questions about our data deletion process or need
              assistance, please contact us:
            </p>
            <div className="contact-info">
              <p>
                <strong>Email:</strong>{" "}
                <a href="mailto:banatalkmain@gmail.com">
                  banatalkmain@gmail.com
                </a>
              </p>
              <p>
                <strong>Subject:</strong> Data Deletion Inquiry
              </p>
              <p>
                <strong>Website:</strong>{" "}
                <a
                  href="http://banatalk.com"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  banatalk.com
                </a>
              </p>
            </div>
            <p>
              We typically respond to data deletion requests within 2-3 business
              days and complete the deletion within 30 days.
            </p>
          </section>

          <section className="policy-section">
            <h2>Your Rights</h2>
            <p>
              Under various data protection laws (including GDPR, CCPA), you
              have the right to:
            </p>
            <ul>
              <li>Request deletion of your personal data</li>
              <li>Access a copy of your personal data</li>
              <li>Correct inaccurate personal data</li>
              <li>Object to processing of your personal data</li>
              <li>Request data portability</li>
            </ul>
            <p>
              For more information about your privacy rights, please review our{" "}
              <Link to="/privacy-policy">Privacy Policy</Link>.
            </p>
          </section>

          <div className="back-link">
            <Link to="/">&larr; Back to Home</Link>
          </div>
        </div>
      </div>
    </>
  );
};

export default DataDeletion;
