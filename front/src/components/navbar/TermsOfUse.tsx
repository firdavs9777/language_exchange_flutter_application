import React from "react";
import { Container } from "react-bootstrap";

const TermsOfUse = () => {
  return (
    <Container className="py-5">
      <div className="bg-white p-4 rounded shadow-sm">
        <h2 className="mb-3">Terms of Use</h2>
        <p className="text-muted mb-4">Last Updated: December 9, 2025</p>

        <div className="mt-4">
          <h5 className="mb-3">1. Acceptance of Terms</h5>
          <p>
            By accessing or using BananaTalk ("the App"), you agree to be bound
            by these Terms of Use. If you do not agree to these terms, please do
            not use the App.
          </p>

          <h5 className="mb-3 mt-4">2. User Conduct and Content Policy</h5>
          <p>
            BananaTalk maintains a <strong>zero-tolerance policy</strong> for
            objectionable content and abusive behavior. Users are prohibited
            from posting, sharing, or transmitting content that:
          </p>
          <ul>
            <li>Contains hate speech, racism, or discrimination</li>
            <li>Depicts violence, threats, or harassment</li>
            <li>Includes sexually explicit or pornographic material</li>
            <li>Infringes on intellectual property rights</li>
            <li>Contains spam, malware, or phishing attempts</li>
            <li>Promotes illegal activities or dangerous behavior</li>
            <li>Impersonates others or provides false information</li>
          </ul>

          <h5 className="mb-3 mt-4">3. Content Moderation</h5>
          <p>
            BananaTalk employs automated filtering and manual review to moderate
            user-generated content. We commit to reviewing and acting on
            reported content within 24 hours. Actions may include:
          </p>
          <ul>
            <li>Content removal</li>
            <li>User warnings</li>
            <li>Temporary or permanent account suspension</li>
            <li>Reporting to relevant authorities when legally required</li>
          </ul>

          <h5 className="mb-3 mt-4">4. Reporting and Blocking</h5>
          <p>
            Users can report inappropriate content or behavior through the
            in-app reporting mechanism. Users can also block other users to
            prevent unwanted interactions.
          </p>

          <h5 className="mb-3 mt-4">5. VIP Subscription</h5>
          <p>
            BananaTalk offers auto-renewable VIP subscriptions with the
            following pricing:
          </p>
          <ul>
            <li>Monthly: $9.99 USD per month</li>
            <li>Quarterly: $24.99 USD per 3 months</li>
            <li>Yearly: $79.99 USD per year</li>
          </ul>
          <p>
            Subscriptions automatically renew unless canceled at least 24 hours
            before the current period ends. Payment is charged to your iTunes
            Account or Google Play account. Manage subscriptions in your
            device's Account Settings.
          </p>

          <h5 className="mb-3 mt-4">6. Cancellation and Refunds</h5>
          <p>
            You may cancel your subscription at any time through your device
            settings. Refunds are subject to Apple App Store and Google Play
            Store policies.
          </p>

          <h5 className="mb-3 mt-4">7. Account Termination</h5>
          <p>
            We reserve the right to suspend or terminate accounts that violate
            these Terms of Use without prior notice or refund.
          </p>

          <h5 className="mb-3 mt-4">8. Intellectual Property</h5>
          <p>
            Users retain ownership of content they post but grant BananaTalk a
            license to use, display, and distribute this content within the App.
            The App itself, including its design, features, and code, is owned
            by BananaTalk.
          </p>

          <h5 className="mb-3 mt-4">9. Disclaimers</h5>
          <p>
            BananaTalk is provided "as is" without warranties of any kind. We do
            not guarantee uninterrupted access or error-free operation. We are
            not responsible for user-generated content or interactions between
            users.
          </p>

          <h5 className="mb-3 mt-4">10. Limitation of Liability</h5>
          <p>
            BananaTalk is not liable for any indirect, incidental, special, or
            consequential damages arising from your use of the App.
          </p>

          <h5 className="mb-3 mt-4">11. Changes to Terms</h5>
          <p>
            We may update these Terms of Use at any time. Continued use of the
            App after changes constitutes acceptance of the revised terms.
          </p>

          <h5 className="mb-3 mt-4">12. Governing Law</h5>
          <p>These Terms are governed by the laws of [Your Country/State].</p>

          <h5 className="mb-3 mt-4">13. Contact Us</h5>
          <p>
            For questions about these Terms, contact us at: support@banatalk.com
          </p>
        </div>
      </div>
    </Container>
  );
};

export default TermsOfUse;
