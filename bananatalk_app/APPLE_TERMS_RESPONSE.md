# Response to Apple - Guideline 1.2 - User-Generated Content

## Message to Send in App Store Connect

---

**Subject: Re: Guideline 1.2 - Safety - User-Generated Content**

Thank you for your review. We have addressed the requirements for user-generated content moderation in the new build submitted for review.

**Implementation Summary:**

We have implemented a comprehensive Terms of Service (EULA) acceptance system that requires all users to explicitly agree to our terms before using the app. The implementation includes:

**1. Mandatory Terms of Service Acceptance:**
- All new users must accept the Terms of Service during registration
- Existing users who haven't accepted terms are prompted to accept upon app launch
- Users cannot proceed to use the app without accepting the terms
- Terms acceptance is tracked in our backend system

**2. Zero Tolerance Policy - Clearly Stated:**
The Terms of Service prominently features a "Zero Tolerance Policy" section that explicitly states:

- **"BananaTalk has a ZERO TOLERANCE policy for objectionable content and abusive users."**
- The policy clearly prohibits:
  - Harassment, bullying, or threats
  - Hate speech, discrimination, or content promoting violence
  - Sexually explicit, pornographic, or inappropriate content
  - Spam, scams, or fraudulent activities
  - Impersonation or false representation
  - Any content violating applicable laws

- Users are informed that violations will result in immediate account termination
- The acceptance checkbox explicitly states: *"I have read and agree to the Terms of Service and understand that BananaTalk has zero tolerance for objectionable content and abusive users."*

**3. User Flow:**
- **New Users:** Terms screen appears after completing registration (Step 2 of registration)
- **Existing Users:** Terms screen appears on app launch if not previously accepted
- **All Users:** Must check the acceptance box and tap "Accept and Continue" to proceed
- Terms cannot be bypassed - the app requires acceptance before access

**4. Backend Integration:**
- Terms acceptance is stored in our backend database
- Each user's acceptance status is tracked with a timestamp
- This ensures compliance and allows us to re-prompt users if terms are updated

**How to Verify in the New Build:**

1. **For New User Registration:**
   - Complete the registration process (email or OAuth)
   - After completing profile information (Step 2), the Terms of Service screen will appear
   - You will see the prominent "Zero Tolerance Policy" section in red highlighting
   - The acceptance checkbox explicitly mentions "zero tolerance for objectionable content and abusive users"
   - You must check the box and tap "Accept and Continue" to proceed

2. **For Existing Users:**
   - If a test account hasn't accepted terms, launch the app
   - The Terms of Service screen will appear immediately after the splash screen
   - Same acceptance process applies

3. **Key Elements to Review:**
   - The "Zero Tolerance Policy" section (highlighted in red) clearly states our policy
   - The acceptance checkbox text explicitly mentions "zero tolerance for objectionable content and abusive users"
   - Users cannot proceed without accepting
   - Terms cover all required aspects: objectionable content, abusive behavior, content moderation, and account termination

**Additional Safety Measures:**
- In-app reporting system for users to report objectionable content
- Content moderation policies clearly outlined in the terms
- Account termination policy for violations
- User responsibility clearly defined

We believe this implementation fully addresses the requirements of Guideline 1.2. The zero tolerance policy is prominently displayed and explicitly stated in the terms that users must accept.

Please review the new build and let us know if you need any additional information.

Thank you for your consideration.

---

## Alternative Shorter Response

---

**Subject: Re: Guideline 1.2 - Safety - User-Generated Content**

Thank you for your review. We have implemented the required Terms of Service (EULA) acceptance in the new build.

**Key Implementation:**

1. **Mandatory Terms Acceptance:** All users must accept Terms of Service before using the app. This appears during registration for new users and on app launch for existing users who haven't accepted.

2. **Zero Tolerance Policy - Explicitly Stated:** The Terms of Service prominently features a "Zero Tolerance Policy" section that clearly states: *"BananaTalk has a ZERO TOLERANCE policy for objectionable content and abusive users."*

3. **Clear Acceptance Language:** The acceptance checkbox explicitly states: *"I have read and agree to the Terms of Service and understand that BananaTalk has zero tolerance for objectionable content and abusive users."*

4. **Cannot Bypass:** Users must check the acceptance box and tap "Accept and Continue" to proceed. The app blocks access until terms are accepted.

**How to Verify:**
- Complete registration → Terms screen appears after Step 2
- Or launch app with existing account → Terms screen appears if not accepted
- Look for the red-highlighted "Zero Tolerance Policy" section
- Check the acceptance checkbox that mentions "zero tolerance for objectionable content and abusive users"

The new build has been submitted for review. Please verify the implementation.

Thank you.

---

