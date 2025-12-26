import React from "react";
const SupportPage = () => {
  return (
    <div
      style={{
        maxWidth: "800px",
        margin: "0 auto",
        padding: "40px 20px",
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        lineHeight: "1.6",
        color: "#333",
      }}
    >
      {/* Header */}
      <header style={{ textAlign: "center", marginBottom: "50px" }}>
        <h1
          style={{
            fontSize: "2.5rem",
            marginBottom: "10px",
            color: "#1a1a1a",
          }}
        >
          BananaTalk Support
        </h1>
        <p
          style={{
            fontSize: "1.1rem",
            color: "#666",
          }}
        >
          바나나톡 고객지원
        </p>
      </header>

      {/* Welcome Section */}
      <section style={{ marginBottom: "40px" }}>
        <p style={{ fontSize: "1.1rem", textAlign: "center", color: "#555" }}>
          We're here to help! If you have any questions or need assistance with
          BananaTalk, please reach out to us using the contact information
          below.
        </p>
      </section>

      {/* Contact Information */}
      <section
        style={{
          background: "#f8f9fa",
          padding: "30px",
          borderRadius: "12px",
          marginBottom: "40px",
          border: "1px solid #e9ecef",
        }}
      >
        <h2
          style={{
            fontSize: "1.8rem",
            marginBottom: "25px",
            color: "#1a1a1a",
          }}
        >
          Contact Us
        </h2>

        <div style={{ marginBottom: "20px" }}>
          <h3
            style={{
              fontSize: "1.1rem",
              color: "#495057",
              marginBottom: "8px",
              fontWeight: "600",
            }}
          >
            📧 Email Support
          </h3>
          <a
            href="mailto:bananatalkmain@gmail.com"
            style={{
              color: "#007bff",
              textDecoration: "none",
              fontSize: "1.1rem",
            }}
          >
            bananatalkmain@gmail.com
          </a>
        </div>

        <div style={{ marginBottom: "20px" }}>
          <h3
            style={{
              fontSize: "1.1rem",
              color: "#495057",
              marginBottom: "8px",
              fontWeight: "600",
            }}
          >
            📱 Phone Support
          </h3>
          <a
            href="tel:+821082773725"
            style={{
              color: "#007bff",
              textDecoration: "none",
              fontSize: "1.1rem",
            }}
          >
            +82-10-8277-3725
          </a>
        </div>

        <div>
          <h3
            style={{
              fontSize: "1.1rem",
              color: "#495057",
              marginBottom: "8px",
              fontWeight: "600",
            }}
          >
            ⏰ Support Hours
          </h3>
          <p style={{ margin: 0, fontSize: "1rem", color: "#6c757d" }}>
            Monday - Friday: 9:00 AM - 6:00 PM KST
            <br />
            Saturday: 10:00 AM - 4:00 PM KST
            <br />
            Sunday: Closed
          </p>
        </div>
      </section>

      {/* FAQ Section */}
      <section style={{ marginBottom: "40px" }}>
        <h2
          style={{
            fontSize: "1.8rem",
            marginBottom: "25px",
            color: "#1a1a1a",
          }}
        >
          Frequently Asked Questions
        </h2>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            How do I find language partners?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            Browse the "Find Partners" section to discover users learning your
            native language. Filter by language, location, and interests to find
            the perfect match.
          </p>
        </div>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            How do I start chatting with someone?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            Visit any user's profile and tap the "Chat" button to send them a
            message. You can introduce yourself and start practicing languages
            together!
          </p>
        </div>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            Is BananaTalk free to use?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            Yes! BananaTalk is completely free to download and use. We offer
            optional VIP features for users who want enhanced functionality.
          </p>
        </div>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            How do I post moments?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            Tap the "+" button on the Moments tab, add photos or videos, write
            your caption, select categories and tags, then publish to share with
            the community.
          </p>
        </div>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            How do I report inappropriate content or users?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            Tap the three dots menu on any profile or post, select "Report," and
            choose the reason. Our team reviews all reports within 24 hours.
          </p>
        </div>

        <div style={{ marginBottom: "25px" }}>
          <h3
            style={{
              fontSize: "1.2rem",
              color: "#495057",
              marginBottom: "10px",
            }}
          >
            What are VIP features?
          </h3>
          <p style={{ color: "#6c757d", marginLeft: "20px" }}>
            VIP members get stealth mode for profile visits, advanced search
            filters, priority matching, and an ad-free experience. Check the VIP
            section in settings for more details.
          </p>
        </div>
      </section>

      {/* Additional Resources */}
      <section
        style={{
          background: "#e7f3ff",
          padding: "25px",
          borderRadius: "12px",
          marginBottom: "40px",
          border: "1px solid #b3d9ff",
        }}
      >
        <h2
          style={{
            fontSize: "1.5rem",
            marginBottom: "15px",
            color: "#1a1a1a",
          }}
        >
          Additional Resources
        </h2>

        <ul
          style={{
            paddingLeft: "20px",
            color: "#495057",
          }}
        >
          <li style={{ marginBottom: "10px" }}>
            <a
              href="/privacy"
              style={{ color: "#007bff", textDecoration: "none" }}
            >
              Privacy Policy
            </a>
          </li>
          <li style={{ marginBottom: "10px" }}>
            <a
              href="/terms"
              style={{ color: "#007bff", textDecoration: "none" }}
            >
              Terms of Service
            </a>
          </li>
          <li style={{ marginBottom: "10px" }}>
            <a
              href="/community-guidelines"
              style={{ color: "#007bff", textDecoration: "none" }}
            >
              Community Guidelines
            </a>
          </li>
        </ul>
      </section>

      {/* Footer */}
      <footer
        style={{
          textAlign: "center",
          padding: "30px 0",
          borderTop: "1px solid #e9ecef",
          color: "#6c757d",
        }}
      >
        <p style={{ margin: "0 0 10px 0" }}>
          BananaTalk - Your Global Language Community
        </p>
        <p style={{ margin: 0, fontSize: "0.9rem" }}>
          © 2025 BananaTalk. All rights reserved.
        </p>
      </footer>
    </div>
  );
};

export default SupportPage;
