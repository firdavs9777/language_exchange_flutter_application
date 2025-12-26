import React from "react";
import { Link } from "react-router-dom";
import "./PrivacyPolicy.css";
const PrivacyPolicy = () => {
  return (
    <>
      <div className="privacy-policy-container">
        <div className="privacy-policy-content">
          <h1>Privacy Policy for BananaTalk</h1>
          <p className="effective-date">
            <strong>Effective Date:</strong> October 23, 2025
          </p>
          <p className="last-updated">
            <strong>Last Updated:</strong> October 23, 2025
          </p>

          <section className="policy-section">
            <h2>1. Introduction</h2>
            <p>
              Welcome to BananaTalk ("we," "our," or "us"). We are committed to
              protecting your privacy and ensuring the security of your personal
              information. This Privacy Policy explains how we collect, use,
              disclose, and safeguard your information when you use our mobile
              application and web platform (collectively, the "Service").
            </p>
            <p>
              By using BananaTalk, you agree to the collection and use of
              information in accordance with this policy. If you do not agree
              with our policies and practices, please do not use our Service.
            </p>
          </section>

          <section className="policy-section">
            <h2>2. Information We Collect</h2>

            <h3>2.1 Information You Provide to Us</h3>
            <ul>
              <li>
                <strong>Account Information:</strong> Name, email address, date
                of birth, gender, native language, language you want to learn
              </li>
              <li>
                <strong>Profile Information:</strong> Profile photos, bio, MBTI,
                blood type, interests
              </li>
              <li>
                <strong>Content:</strong> Moments (posts), photos, comments,
                chat messages, stories
              </li>
              <li>
                <strong>Social Connections:</strong> Information about your
                followers and people you follow
              </li>
            </ul>

            <h3>2.2 Information Collected Automatically</h3>
            <ul>
              <li>
                <strong>Location Data:</strong> With your permission, we collect
                precise location data to show your location on moments and help
                you connect with nearby users
              </li>
              <li>
                <strong>Device Information:</strong> Device type, operating
                system, unique device identifiers, mobile network information
              </li>
              <li>
                <strong>Usage Data:</strong> How you interact with our Service,
                features you use, time spent on the app
              </li>
              <li>
                <strong>Log Data:</strong> IP address, browser type, pages
                visited, time and date of visits
              </li>
            </ul>

            <h3>2.3 Information from Third Parties</h3>
            <ul>
              <li>
                <strong>Social Media:</strong> If you choose to connect your
                Facebook account, we may receive information from those
                platforms in accordance with their policies
              </li>
            </ul>
          </section>

          <section className="policy-section">
            <h2>3. How We Use Your Information</h2>
            <p>We use the information we collect to:</p>
            <ul>
              <li>Provide, maintain, and improve our Service</li>
              <li>Create and manage your account</li>
              <li>
                Enable you to share moments, chat with other users, and post
                stories
              </li>
              <li>Personalize your experience and show you relevant content</li>
              <li>Connect you with language learning partners</li>
              <li>
                Show location-based content when you enable location services
              </li>
              <li>Send you notifications about activity on your account</li>
              <li>
                Respond to your comments, questions, and customer service
                requests
              </li>
              <li>
                Detect, prevent, and address technical issues and security
                threats
              </li>
              <li>Comply with legal obligations</li>
              <li>Analyze usage patterns to improve our Service</li>
            </ul>
          </section>

          <section className="policy-section">
            <h2>4. How We Share Your Information</h2>

            <h3>4.1 Public Information</h3>
            <p>
              Content you post as "Public" (moments, comments, profile
              information) can be viewed by all BananaTalk users and may appear
              in search results.
            </p>

            <h3>4.2 With Other Users</h3>
            <ul>
              <li>Your profile information is visible to other users</li>
              <li>
                Moments you post are visible based on your privacy settings
                (Public, Friends, Private)
              </li>
              <li>
                Chat messages are only visible to participants in the
                conversation
              </li>
            </ul>

            <h3>4.3 Service Providers</h3>
            <p>
              We may share your information with third-party service providers
              who perform services on our behalf, such as:
            </p>
            <ul>
              <li>Cloud hosting providers</li>
              <li>Analytics services</li>
              <li>Customer support tools</li>
              <li>Communication platforms</li>
            </ul>

            <h3>4.4 Legal Requirements</h3>
            <p>
              We may disclose your information if required by law or in response
              to valid requests by public authorities.
            </p>

            <h3>4.5 Business Transfers</h3>
            <p>
              If BananaTalk is involved in a merger, acquisition, or sale of
              assets, your information may be transferred as part of that
              transaction.
            </p>
          </section>

          <section className="policy-section">
            <h2>5. Data Retention</h2>
            <p>
              We retain your information for as long as your account is active
              or as needed to provide you with our Service. You may request
              deletion of your account and data at any time through the app
              settings.
            </p>
            <p>
              After account deletion, we may retain certain information as
              required by law or for legitimate business purposes, such as fraud
              prevention.
            </p>
          </section>

          <section className="policy-section">
            <h2>6. Your Rights and Choices</h2>

            <h3>6.1 Access and Update</h3>
            <p>
              You can access and update your account information at any time
              through your profile settings.
            </p>

            <h3>6.2 Privacy Settings</h3>
            <p>
              You can control who sees your moments by selecting privacy
              options: Public, Friends, or Private.
            </p>

            <h3>6.3 Location Data</h3>
            <p>
              You can disable location services through your device settings at
              any time. This may limit some features of the app.
            </p>

            <h3>6.4 Notifications</h3>
            <p>
              You can manage notification preferences through the app settings.
            </p>

            <h3>6.5 Account Deletion</h3>
            <p>
              You may delete your account at any time. Upon deletion, your
              profile and content will be removed from our Service.
            </p>

            <h3>6.6 Data Portability</h3>
            <p>
              You have the right to request a copy of your data in a
              machine-readable format.
            </p>
          </section>

          <section className="policy-section">
            <h2>7. Children's Privacy</h2>
            <p>
              BananaTalk is not intended for children under the age of 13. We do
              not knowingly collect personal information from children under 13.
              If you are a parent or guardian and believe your child has
              provided us with personal information, please contact us, and we
              will delete such information from our systems.
            </p>
          </section>

          <section className="policy-section">
            <h2>8. Security</h2>
            <p>
              We implement reasonable security measures to protect your
              information from unauthorized access, alteration, disclosure, or
              destruction. However, no method of transmission over the internet
              or electronic storage is 100% secure, and we cannot guarantee
              absolute security.
            </p>
            <p>Security measures we implement include:</p>
            <ul>
              <li>Encryption of data in transit and at rest</li>
              <li>Regular security audits and updates</li>
              <li>Access controls and authentication</li>
              <li>Secure server infrastructure</li>
            </ul>
          </section>

          <section className="policy-section">
            <h2>9. International Data Transfers</h2>
            <p>
              Your information may be transferred to and processed in countries
              other than your country of residence. These countries may have
              different data protection laws. By using our Service, you consent
              to the transfer of your information to these countries.
            </p>
          </section>

          <section className="policy-section">
            <h2>10. Third-Party Links</h2>
            <p>
              Our Service may contain links to third-party websites or services.
              We are not responsible for the privacy practices of these third
              parties. We encourage you to read their privacy policies before
              providing any information.
            </p>
          </section>

          <section className="policy-section">
            <h2>11. Changes to This Privacy Policy</h2>
            <p>
              We may update this Privacy Policy from time to time. We will
              notify you of any changes by posting the new Privacy Policy on
              this page and updating the "Last Updated" date. You are advised to
              review this Privacy Policy periodically for any changes.
            </p>
            <p>
              Continued use of the Service after changes are posted constitutes
              your acceptance of the updated Privacy Policy.
            </p>
          </section>

          <h2>12. Contact Us</h2>
          <p>
            If you have any questions, concerns, or requests regarding this
            Privacy Policy or our data practices, please contact us:
          </p>
          <div className="contact-info">
            <p>
              <strong>Email:</strong>{" "}
              <a href="mailto:bananatalkmain@gmail.com">
                bananatalkmain@gmail.com
              </a>
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

          <section className="policy-section">
            <h2>13. Your Consent</h2>
            <p>
              By using BananaTalk, you consent to our Privacy Policy and agree
              to its terms.
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
export default PrivacyPolicy;
