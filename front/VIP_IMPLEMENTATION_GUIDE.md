# BananaTalk VIP System - Frontend Web Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [VIP Tiers & Benefits](#vip-tiers--benefits)
3. [API Hooks Reference](#api-hooks-reference)
4. [Screen 1: VIP Landing Page](#screen-1-vip-landing-page)
5. [Screen 2: Plan Selection](#screen-2-plan-selection)
6. [Screen 3: Payment/Checkout](#screen-3-paymentcheckout)
7. [Screen 4: VIP Dashboard](#screen-4-vip-dashboard)
8. [Screen 5: Manage Subscription](#screen-5-manage-subscription)
9. [VIP Feature Gates](#vip-feature-gates)
10. [VIP Badges & Indicators](#vip-badges--indicators)
11. [State Management](#state-management)
12. [Payment Integration](#payment-integration)
13. [Components Library](#components-library)
14. [Styling Guidelines](#styling-guidelines)
15. [Testing Checklist](#testing-checklist)

---

## Overview

The VIP system provides premium features to paying subscribers with three tiers:
- **Free** - Basic features with limitations
- **VIP Monthly** - Full access, billed monthly
- **VIP Yearly** - Full access, billed yearly (discounted)

### File Structure

```
src/components/vip/
├── VipLanding.tsx              # Marketing/benefits page
├── VipLanding.scss
├── PlanSelection.tsx           # Choose plan
├── PlanSelection.scss
├── Checkout.tsx                # Payment form
├── Checkout.scss
├── VipDashboard.tsx            # VIP member dashboard
├── VipDashboard.scss
├── ManageSubscription.tsx      # Cancel/change plan
├── ManageSubscription.scss
├── components/
│   ├── PlanCard.tsx            # Single plan display
│   ├── PlanCard.scss
│   ├── FeatureComparison.tsx   # Feature comparison table
│   ├── VipBadge.tsx            # VIP indicator badge
│   ├── VipBadge.scss
│   ├── FeatureGate.tsx         # Wrapper for VIP features
│   ├── UpgradePrompt.tsx       # Upgrade modal/banner
│   ├── UpgradePrompt.scss
│   ├── BillingHistory.tsx      # Past payments
│   ├── PaymentMethod.tsx       # Saved cards
│   └── CancelModal.tsx         # Cancellation flow
├── hooks/
│   ├── useVipStatus.ts         # Check VIP status
│   ├── useFeatureAccess.ts     # Check feature access
│   └── useSubscription.ts      # Subscription management
└── utils/
    ├── vipFeatures.ts          # Feature definitions
    └── planPricing.ts          # Pricing helpers
```

---

## VIP Tiers & Benefits

### Feature Comparison Table

| Feature | Free | VIP |
|---------|------|-----|
| **Messaging** | | |
| Messages per day | 20 | Unlimited |
| Voice messages | 5/day | Unlimited |
| Send images | 10/day | Unlimited |
| Message translation | 3/day | Unlimited |
| | | |
| **Community** | | |
| View profiles | 30/day | Unlimited |
| Send waves | 5/day | Unlimited |
| See who viewed profile | ❌ | ✅ |
| Advanced filters | Basic | All filters |
| See online status | ✅ | ✅ |
| Nearby users | ❌ | ✅ |
| | | |
| **Stories & Moments** | | |
| Post moments | 3/day | Unlimited |
| Post stories | 5/day | Unlimited |
| Story highlights | 1 | Unlimited |
| Close friends list | ❌ | ✅ |
| | | |
| **Learning** | | |
| Vocabulary words | 100 max | Unlimited |
| Lessons per day | 3 | Unlimited |
| Quizzes per day | 2 | Unlimited |
| AI corrections | ❌ | ✅ |
| | | |
| **Profile** | | |
| Photos | 5 | 15 |
| VIP badge | ❌ | ✅ |
| Priority in search | ❌ | ✅ |
| Profile boost | ❌ | 1/week |
| | | |
| **Other** | | |
| Ads | Yes | No ads |
| Support | Standard | Priority |

### Pricing Structure

```typescript
// utils/planPricing.ts
export const VIP_PLANS = {
  monthly: {
    id: 'vip_monthly',
    name: 'VIP Monthly',
    price: 9.99,
    currency: 'USD',
    interval: 'month',
    intervalCount: 1,
    features: ['All VIP features', 'Cancel anytime'],
    popular: false,
  },
  yearly: {
    id: 'vip_yearly',
    name: 'VIP Yearly',
    price: 79.99,
    currency: 'USD',
    interval: 'year',
    intervalCount: 1,
    monthlyEquivalent: 6.67,
    savings: 40, // percentage
    features: ['All VIP features', '2 months free', 'Best value'],
    popular: true,
  },
};

export const formatPrice = (price: number, currency: string = 'USD') => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(price);
};
```

### Feature Definitions

```typescript
// utils/vipFeatures.ts
export enum VipFeature {
  // Messaging
  UNLIMITED_MESSAGES = 'unlimited_messages',
  UNLIMITED_VOICE = 'unlimited_voice',
  UNLIMITED_IMAGES = 'unlimited_images',
  UNLIMITED_TRANSLATION = 'unlimited_translation',

  // Community
  UNLIMITED_PROFILE_VIEWS = 'unlimited_profile_views',
  UNLIMITED_WAVES = 'unlimited_waves',
  SEE_PROFILE_VISITORS = 'see_profile_visitors',
  ADVANCED_FILTERS = 'advanced_filters',
  NEARBY_USERS = 'nearby_users',

  // Stories & Moments
  UNLIMITED_MOMENTS = 'unlimited_moments',
  UNLIMITED_STORIES = 'unlimited_stories',
  UNLIMITED_HIGHLIGHTS = 'unlimited_highlights',
  CLOSE_FRIENDS = 'close_friends',

  // Learning
  UNLIMITED_VOCABULARY = 'unlimited_vocabulary',
  UNLIMITED_LESSONS = 'unlimited_lessons',
  UNLIMITED_QUIZZES = 'unlimited_quizzes',
  AI_CORRECTIONS = 'ai_corrections',

  // Profile
  EXTRA_PHOTOS = 'extra_photos',
  VIP_BADGE = 'vip_badge',
  PRIORITY_SEARCH = 'priority_search',
  PROFILE_BOOST = 'profile_boost',

  // Other
  NO_ADS = 'no_ads',
  PRIORITY_SUPPORT = 'priority_support',
}

export const FREE_LIMITS: Record<string, number> = {
  messages_per_day: 20,
  voice_per_day: 5,
  images_per_day: 10,
  translations_per_day: 3,
  profile_views_per_day: 30,
  waves_per_day: 5,
  moments_per_day: 3,
  stories_per_day: 5,
  highlights_max: 1,
  vocabulary_max: 100,
  lessons_per_day: 3,
  quizzes_per_day: 2,
  photos_max: 5,
};

export const VIP_LIMITS: Record<string, number> = {
  messages_per_day: Infinity,
  voice_per_day: Infinity,
  images_per_day: Infinity,
  translations_per_day: Infinity,
  profile_views_per_day: Infinity,
  waves_per_day: Infinity,
  moments_per_day: Infinity,
  stories_per_day: Infinity,
  highlights_max: Infinity,
  vocabulary_max: Infinity,
  lessons_per_day: Infinity,
  quizzes_per_day: Infinity,
  photos_max: 15,
};
```

---

## API Hooks Reference

### Add to usersSlice.ts

```typescript
// VIP Status
useGetVipStatusQuery(userId)

// Already exists in usersSlice.ts:
// - useGetVipStatusQuery
// - useGetUserLimitsQuery
```

### Add new vipSlice.ts

```typescript
// src/store/slices/vipSlice.ts
import { VIP_URL } from "../../constants";
import { apiSlice } from "./apiSlice";

export const vipApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Get VIP status
    getMyVipStatus: builder.query({
      query: () => ({
        url: `${VIP_URL}/status`,
      }),
      providesTags: ["Vip"],
    }),

    // Get available plans
    getVipPlans: builder.query({
      query: () => ({
        url: `${VIP_URL}/plans`,
      }),
    }),

    // Create checkout session (Stripe)
    createCheckoutSession: builder.mutation({
      query: (data: { planId: string; successUrl: string; cancelUrl: string }) => ({
        url: `${VIP_URL}/checkout/session`,
        method: "POST",
        body: data,
      }),
    }),

    // Verify payment
    verifyPayment: builder.mutation({
      query: (sessionId: string) => ({
        url: `${VIP_URL}/checkout/verify`,
        method: "POST",
        body: { sessionId },
      }),
      invalidatesTags: ["Vip", "User"],
    }),

    // Get subscription details
    getSubscription: builder.query({
      query: () => ({
        url: `${VIP_URL}/subscription`,
      }),
      providesTags: ["Vip"],
    }),

    // Cancel subscription
    cancelSubscription: builder.mutation({
      query: (data?: { reason?: string; feedback?: string }) => ({
        url: `${VIP_URL}/subscription/cancel`,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Vip", "User"],
    }),

    // Reactivate subscription
    reactivateSubscription: builder.mutation({
      query: () => ({
        url: `${VIP_URL}/subscription/reactivate`,
        method: "POST",
      }),
      invalidatesTags: ["Vip", "User"],
    }),

    // Change plan
    changePlan: builder.mutation({
      query: (planId: string) => ({
        url: `${VIP_URL}/subscription/change`,
        method: "POST",
        body: { planId },
      }),
      invalidatesTags: ["Vip"],
    }),

    // Get billing history
    getBillingHistory: builder.query({
      query: ({ page = 1, limit = 10 } = {}) => ({
        url: `${VIP_URL}/billing/history?page=${page}&limit=${limit}`,
      }),
    }),

    // Get payment methods
    getPaymentMethods: builder.query({
      query: () => ({
        url: `${VIP_URL}/payment-methods`,
      }),
      providesTags: ["PaymentMethods"],
    }),

    // Add payment method
    addPaymentMethod: builder.mutation({
      query: (paymentMethodId: string) => ({
        url: `${VIP_URL}/payment-methods`,
        method: "POST",
        body: { paymentMethodId },
      }),
      invalidatesTags: ["PaymentMethods"],
    }),

    // Remove payment method
    removePaymentMethod: builder.mutation({
      query: (paymentMethodId: string) => ({
        url: `${VIP_URL}/payment-methods/${paymentMethodId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["PaymentMethods"],
    }),

    // Set default payment method
    setDefaultPaymentMethod: builder.mutation({
      query: (paymentMethodId: string) => ({
        url: `${VIP_URL}/payment-methods/${paymentMethodId}/default`,
        method: "PUT",
      }),
      invalidatesTags: ["PaymentMethods"],
    }),

    // Apply promo code
    applyPromoCode: builder.mutation({
      query: (code: string) => ({
        url: `${VIP_URL}/promo/apply`,
        method: "POST",
        body: { code },
      }),
    }),

    // Validate promo code
    validatePromoCode: builder.query({
      query: (code: string) => ({
        url: `${VIP_URL}/promo/validate?code=${code}`,
      }),
    }),

    // Get usage stats (for limits)
    getUsageStats: builder.query({
      query: () => ({
        url: `${VIP_URL}/usage`,
      }),
      providesTags: ["Usage"],
    }),

    // Use profile boost (VIP feature)
    useProfileBoost: builder.mutation({
      query: () => ({
        url: `${VIP_URL}/boost`,
        method: "POST",
      }),
      invalidatesTags: ["Vip", "User"],
    }),
  }),
});

export const {
  useGetMyVipStatusQuery,
  useGetVipPlansQuery,
  useCreateCheckoutSessionMutation,
  useVerifyPaymentMutation,
  useGetSubscriptionQuery,
  useCancelSubscriptionMutation,
  useReactivateSubscriptionMutation,
  useChangePlanMutation,
  useGetBillingHistoryQuery,
  useGetPaymentMethodsQuery,
  useAddPaymentMethodMutation,
  useRemovePaymentMethodMutation,
  useSetDefaultPaymentMethodMutation,
  useApplyPromoCodeMutation,
  useValidatePromoCodeQuery,
  useGetUsageStatsQuery,
  useProfileBoostMutation,
} = vipApiSlice;

export default vipApiSlice.reducer;
```

### Update constants.ts

```typescript
// Add to constants.ts
export const VIP_URL = "/api/v1/vip";
```

### Update apiSlice.ts tagTypes

```typescript
tagTypes: [
  // ... existing tags
  "Vip",
  "PaymentMethods",
  "Usage",
],
```

---

## Screen 1: VIP Landing Page

**Route:** `/vip`
**File:** `src/components/vip/VipLanding.tsx`

### Purpose
Marketing page to showcase VIP benefits and convert free users.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    ✨ BananaTalk VIP ✨                     │
│                                                             │
│              Unlock the full language learning              │
│                      experience                             │
│                                                             │
│                   [Get VIP Now →]                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     ┌───────────────────────────────────────────────┐       │
│     │                                               │       │
│     │          🎥 Feature Video/Animation           │       │
│     │                                               │       │
│     └───────────────────────────────────────────────┘       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    VIP Benefits                             │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │     💬      │ │     👥      │ │     📚      │           │
│  │  Unlimited  │ │   See Who   │ │  Unlimited  │           │
│  │  Messages   │ │ Viewed You  │ │  Learning   │           │
│  │             │ │             │ │             │           │
│  │ Chat without│ │ Know your   │ │ No limits   │           │
│  │ any limits  │ │ admirers    │ │ on lessons  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │     🚫      │ │     🎯      │ │     ⭐      │           │
│  │   No Ads    │ │  Advanced   │ │    VIP      │           │
│  │             │ │  Filters    │ │   Badge     │           │
│  │             │ │             │ │             │           │
│  │ Ad-free     │ │ Find exact  │ │ Stand out   │           │
│  │ experience  │ │ matches     │ │ in community│           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│               Compare Free vs VIP                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Feature              │    Free    │      VIP       │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ Messages/day         │     20     │   Unlimited    │   │
│  │ Profile views/day    │     30     │   Unlimited    │   │
│  │ See profile visitors │     ❌     │      ✅        │   │
│  │ Vocabulary words     │    100     │   Unlimited    │   │
│  │ Ads                  │    Yes     │      No        │   │
│  │ VIP Badge            │     ❌     │      ✅        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│                   [View All Features]                       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                  Choose Your Plan                           │
│                                                             │
│     ┌───────────────────┐   ┌───────────────────┐          │
│     │                   │   │  ⭐ BEST VALUE    │          │
│     │     Monthly       │   │      Yearly       │          │
│     │                   │   │                   │          │
│     │     $9.99         │   │     $79.99        │          │
│     │    /month         │   │     /year         │          │
│     │                   │   │                   │          │
│     │                   │   │   $6.67/month     │          │
│     │                   │   │   Save 33%        │          │
│     │                   │   │                   │          │
│     │  [Select Plan]    │   │  [Select Plan]    │          │
│     └───────────────────┘   └───────────────────┘          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                   What Members Say                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ "VIP changed my learning experience completely!"    │   │
│  │                           - Sarah, Seoul            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ "Worth every penny. The profile visitors feature    │   │
│  │  helped me connect with so many people."            │   │
│  │                           - John, Tokyo             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        FAQ                                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ▶ Can I cancel anytime?                             │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ▶ What payment methods do you accept?               │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ▶ Is there a free trial?                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│         🍌 Start your VIP journey today! 🍌                 │
│                                                             │
│                  [Get VIP Now →]                            │
│                                                             │
│            30-day money-back guarantee                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// VipLanding.tsx
import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { useGetMyVipStatusQuery } from '../../store/slices/vipSlice';
import { RootState } from '../../store';
import PlanCard from './components/PlanCard';
import FeatureComparison from './components/FeatureComparison';
import { VIP_PLANS } from './utils/planPricing';
import './VipLanding.scss';

const BENEFITS = [
  {
    icon: '💬',
    title: 'Unlimited Messages',
    description: 'Chat without any daily limits',
  },
  {
    icon: '👥',
    title: 'See Who Viewed You',
    description: 'Know who checked your profile',
  },
  {
    icon: '📚',
    title: 'Unlimited Learning',
    description: 'No limits on lessons & vocabulary',
  },
  {
    icon: '🚫',
    title: 'No Ads',
    description: 'Enjoy an ad-free experience',
  },
  {
    icon: '🎯',
    title: 'Advanced Filters',
    description: 'Find your perfect language partner',
  },
  {
    icon: '⭐',
    title: 'VIP Badge',
    description: 'Stand out in the community',
  },
];

const TESTIMONIALS = [
  {
    text: "VIP changed my learning experience completely! The unlimited messaging helped me practice daily.",
    author: "Sarah",
    location: "Seoul",
  },
  {
    text: "Worth every penny. The profile visitors feature helped me connect with so many people.",
    author: "John",
    location: "Tokyo",
  },
];

const FAQS = [
  {
    question: "Can I cancel anytime?",
    answer: "Yes! You can cancel your subscription at any time. You'll continue to have VIP access until the end of your billing period.",
  },
  {
    question: "What payment methods do you accept?",
    answer: "We accept all major credit cards (Visa, MasterCard, American Express), PayPal, and Apple Pay.",
  },
  {
    question: "Is there a free trial?",
    answer: "We offer a 7-day free trial for new VIP subscribers. You can cancel anytime during the trial.",
  },
  {
    question: "Can I switch between monthly and yearly?",
    answer: "Yes, you can change your plan at any time. The change will take effect on your next billing date.",
  },
];

const VipLanding: React.FC = () => {
  const navigate = useNavigate();
  const [expandedFaq, setExpandedFaq] = React.useState<number | null>(null);

  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const isLoggedIn = !!userInfo?.token;

  const { data: vipStatus } = useGetMyVipStatusQuery(undefined, {
    skip: !isLoggedIn,
  });

  const isVip = vipStatus?.data?.isVIP;

  const handleSelectPlan = (planId: string) => {
    if (!isLoggedIn) {
      navigate('/login?redirect=/vip/checkout?plan=' + planId);
      return;
    }
    navigate(`/vip/checkout?plan=${planId}`);
  };

  // If already VIP, redirect to dashboard
  if (isVip) {
    navigate('/vip/dashboard');
    return null;
  }

  return (
    <div className="vip-landing">
      {/* Hero Section */}
      <section className="hero-section">
        <div className="hero-content">
          <h1>✨ BananaTalk VIP ✨</h1>
          <p className="hero-subtitle">
            Unlock the full language learning experience
          </p>
          <button
            className="cta-button primary"
            onClick={() => navigate('/vip/plans')}
          >
            Get VIP Now →
          </button>
        </div>
        <div className="hero-visual">
          {/* Add illustration or video */}
          <img src="/images/vip-hero.png" alt="VIP Features" />
        </div>
      </section>

      {/* Benefits Grid */}
      <section className="benefits-section">
        <h2>VIP Benefits</h2>
        <div className="benefits-grid">
          {BENEFITS.map((benefit, index) => (
            <div key={index} className="benefit-card">
              <span className="benefit-icon">{benefit.icon}</span>
              <h3>{benefit.title}</h3>
              <p>{benefit.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Feature Comparison */}
      <section className="comparison-section">
        <h2>Compare Free vs VIP</h2>
        <FeatureComparison />
        <button
          className="view-all-btn"
          onClick={() => navigate('/vip/features')}
        >
          View All Features
        </button>
      </section>

      {/* Plans Section */}
      <section className="plans-section">
        <h2>Choose Your Plan</h2>
        <div className="plans-grid">
          <PlanCard
            plan={VIP_PLANS.monthly}
            onSelect={() => handleSelectPlan('vip_monthly')}
          />
          <PlanCard
            plan={VIP_PLANS.yearly}
            onSelect={() => handleSelectPlan('vip_yearly')}
            highlighted
          />
        </div>
      </section>

      {/* Testimonials */}
      <section className="testimonials-section">
        <h2>What Members Say</h2>
        <div className="testimonials-grid">
          {TESTIMONIALS.map((testimonial, index) => (
            <div key={index} className="testimonial-card">
              <p className="testimonial-text">"{testimonial.text}"</p>
              <p className="testimonial-author">
                - {testimonial.author}, {testimonial.location}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ Section */}
      <section className="faq-section">
        <h2>Frequently Asked Questions</h2>
        <div className="faq-list">
          {FAQS.map((faq, index) => (
            <div
              key={index}
              className={`faq-item ${expandedFaq === index ? 'expanded' : ''}`}
            >
              <button
                className="faq-question"
                onClick={() => setExpandedFaq(expandedFaq === index ? null : index)}
              >
                <span>{faq.question}</span>
                <span className="faq-icon">
                  {expandedFaq === index ? '−' : '+'}
                </span>
              </button>
              {expandedFaq === index && (
                <div className="faq-answer">
                  <p>{faq.answer}</p>
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* Final CTA */}
      <section className="final-cta-section">
        <h2>🍌 Start your VIP journey today! 🍌</h2>
        <button
          className="cta-button primary large"
          onClick={() => navigate('/vip/plans')}
        >
          Get VIP Now →
        </button>
        <p className="guarantee">30-day money-back guarantee</p>
      </section>
    </div>
  );
};

export default VipLanding;
```

---

## Screen 2: Plan Selection

**Route:** `/vip/plans`
**File:** `src/components/vip/PlanSelection.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]              Choose Your Plan                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│        Select the plan that works best for you              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │                    💎 VIP MONTHLY                   │    │
│  │                                                     │    │
│  │                      $9.99                          │    │
│  │                     /month                          │    │
│  │                                                     │    │
│  │  ✓ All VIP features                                │    │
│  │  ✓ Cancel anytime                                  │    │
│  │  ✓ Instant activation                              │    │
│  │                                                     │    │
│  │               [Select Monthly]                      │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ⭐ BEST VALUE                           SAVE 33%   │    │
│  │─────────────────────────────────────────────────────│    │
│  │                                                     │    │
│  │                    👑 VIP YEARLY                    │    │
│  │                                                     │    │
│  │                      $79.99                         │    │
│  │                      /year                          │    │
│  │                                                     │    │
│  │                  Only $6.67/month                   │    │
│  │                                                     │    │
│  │  ✓ All VIP features                                │    │
│  │  ✓ 2 months FREE                                   │    │
│  │  ✓ Priority support                                │    │
│  │  ✓ Exclusive yearly badge                          │    │
│  │                                                     │    │
│  │               [Select Yearly]                       │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Have a promo code?                                         │
│  ┌─────────────────────────────────┐  [Apply]              │
│  │ Enter code...                   │                        │
│  └─────────────────────────────────┘                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔒 Secure payment powered by Stripe                        │
│     Cancel anytime • 30-day money-back guarantee           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### PlanCard Component

```typescript
// components/PlanCard.tsx
import React from 'react';
import { formatPrice } from '../utils/planPricing';
import './PlanCard.scss';

interface Plan {
  id: string;
  name: string;
  price: number;
  currency: string;
  interval: string;
  monthlyEquivalent?: number;
  savings?: number;
  features: string[];
  popular?: boolean;
}

interface PlanCardProps {
  plan: Plan;
  onSelect: () => void;
  highlighted?: boolean;
  selected?: boolean;
}

const PlanCard: React.FC<PlanCardProps> = ({
  plan,
  onSelect,
  highlighted = false,
  selected = false,
}) => {
  return (
    <div
      className={`plan-card ${highlighted ? 'highlighted' : ''} ${selected ? 'selected' : ''}`}
    >
      {/* Badge */}
      {plan.popular && (
        <div className="plan-badge">
          <span>⭐ BEST VALUE</span>
          {plan.savings && <span className="savings">SAVE {plan.savings}%</span>}
        </div>
      )}

      {/* Plan Header */}
      <div className="plan-header">
        <span className="plan-icon">{plan.interval === 'year' ? '👑' : '💎'}</span>
        <h3 className="plan-name">{plan.name}</h3>
      </div>

      {/* Price */}
      <div className="plan-price">
        <span className="price-amount">{formatPrice(plan.price, plan.currency)}</span>
        <span className="price-interval">/{plan.interval}</span>
      </div>

      {/* Monthly equivalent for yearly */}
      {plan.monthlyEquivalent && (
        <p className="monthly-equivalent">
          Only {formatPrice(plan.monthlyEquivalent, plan.currency)}/month
        </p>
      )}

      {/* Features */}
      <ul className="plan-features">
        {plan.features.map((feature, index) => (
          <li key={index}>
            <span className="check">✓</span>
            {feature}
          </li>
        ))}
      </ul>

      {/* Select Button */}
      <button
        className={`select-button ${highlighted ? 'primary' : 'secondary'}`}
        onClick={onSelect}
      >
        Select {plan.interval === 'year' ? 'Yearly' : 'Monthly'}
      </button>
    </div>
  );
};

export default PlanCard;
```

---

## Screen 3: Payment/Checkout

**Route:** `/vip/checkout`
**File:** `src/components/vip/Checkout.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]              Checkout                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Order Summary                                      │    │
│  │─────────────────────────────────────────────────────│    │
│  │                                                     │    │
│  │  VIP Yearly Plan                         $79.99    │    │
│  │                                                     │    │
│  │  Promo Code: WELCOME20                  -$16.00    │    │
│  │                                                     │    │
│  │─────────────────────────────────────────────────────│    │
│  │  Total                                   $63.99    │    │
│  │                                                     │    │
│  │  Billed yearly. Next charge: Jan 15, 2025         │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Payment Method                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │  Card Number                                        │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │ 4242 4242 4242 4242                     💳  │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  │                                                     │    │
│  │  ┌──────────────────┐  ┌──────────────────┐        │    │
│  │  │ Expiry           │  │ CVC              │        │    │
│  │  │ 12/25            │  │ 123              │        │    │
│  │  └──────────────────┘  └──────────────────┘        │    │
│  │                                                     │    │
│  │  Name on Card                                       │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │ John Doe                                    │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ☑ Save card for future payments                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│             [Complete Purchase - $63.99]                    │
│                                                             │
│  🔒 Secure payment • 256-bit SSL encryption                │
│                                                             │
│  By completing this purchase, you agree to our              │
│  Terms of Service and Privacy Policy.                       │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Other payment options:                                     │
│                                                             │
│  [PayPal]  [Apple Pay]  [Google Pay]                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Checkout Component (Stripe Integration)

```typescript
// Checkout.tsx
import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { loadStripe } from '@stripe/stripe-js';
import {
  Elements,
  CardElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js';
import {
  useCreateCheckoutSessionMutation,
  useVerifyPaymentMutation,
  useApplyPromoCodeMutation,
} from '../../store/slices/vipSlice';
import { VIP_PLANS, formatPrice } from './utils/planPricing';
import './Checkout.scss';

const stripePromise = loadStripe(process.env.REACT_APP_STRIPE_PUBLIC_KEY!);

interface CheckoutFormProps {
  planId: string;
  promoCode?: string;
  discount?: number;
}

const CheckoutForm: React.FC<CheckoutFormProps> = ({
  planId,
  promoCode,
  discount = 0,
}) => {
  const stripe = useStripe();
  const elements = useElements();
  const navigate = useNavigate();

  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saveCard, setSaveCard] = useState(true);

  const [createCheckoutSession] = useCreateCheckoutSessionMutation();
  const [verifyPayment] = useVerifyPaymentMutation();

  const plan = planId === 'vip_yearly' ? VIP_PLANS.yearly : VIP_PLANS.monthly;
  const finalPrice = plan.price - discount;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setIsProcessing(true);
    setError(null);

    try {
      // Create checkout session
      const { data: session } = await createCheckoutSession({
        planId,
        successUrl: `${window.location.origin}/vip/success`,
        cancelUrl: `${window.location.origin}/vip/checkout?plan=${planId}`,
      }).unwrap();

      // Redirect to Stripe Checkout
      const result = await stripe.redirectToCheckout({
        sessionId: session.sessionId,
      });

      if (result.error) {
        setError(result.error.message || 'Payment failed');
      }
    } catch (err: any) {
      setError(err.data?.message || 'Payment failed. Please try again.');
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="checkout-form">
      {/* Order Summary */}
      <div className="order-summary">
        <h3>Order Summary</h3>
        <div className="summary-row">
          <span>{plan.name}</span>
          <span>{formatPrice(plan.price)}</span>
        </div>
        {discount > 0 && (
          <div className="summary-row discount">
            <span>Promo Code: {promoCode}</span>
            <span>-{formatPrice(discount)}</span>
          </div>
        )}
        <div className="summary-total">
          <span>Total</span>
          <span>{formatPrice(finalPrice)}</span>
        </div>
        <p className="billing-note">
          Billed {plan.interval === 'year' ? 'yearly' : 'monthly'}.
          Next charge: {new Date(Date.now() + (plan.interval === 'year' ? 365 : 30) * 24 * 60 * 60 * 1000).toLocaleDateString()}
        </p>
      </div>

      {/* Card Element */}
      <div className="payment-section">
        <h3>Payment Method</h3>
        <div className="card-element-container">
          <CardElement
            options={{
              style: {
                base: {
                  fontSize: '16px',
                  color: '#1a1a1a',
                  '::placeholder': { color: '#9e9e9e' },
                },
                invalid: { color: '#e53935' },
              },
            }}
          />
        </div>

        <label className="save-card-checkbox">
          <input
            type="checkbox"
            checked={saveCard}
            onChange={(e) => setSaveCard(e.target.checked)}
          />
          Save card for future payments
        </label>
      </div>

      {/* Error Display */}
      {error && <div className="error-message">{error}</div>}

      {/* Submit Button */}
      <button
        type="submit"
        className="checkout-button"
        disabled={!stripe || isProcessing}
      >
        {isProcessing ? 'Processing...' : `Complete Purchase - ${formatPrice(finalPrice)}`}
      </button>

      {/* Security Note */}
      <p className="security-note">
        🔒 Secure payment • 256-bit SSL encryption
      </p>

      <p className="terms-note">
        By completing this purchase, you agree to our{' '}
        <a href="/terms">Terms of Service</a> and{' '}
        <a href="/privacy">Privacy Policy</a>.
      </p>

      {/* Alternative Payment Methods */}
      <div className="alternative-payments">
        <p>Other payment options:</p>
        <div className="payment-buttons">
          <button type="button" className="paypal-btn">PayPal</button>
          <button type="button" className="apple-pay-btn">Apple Pay</button>
          <button type="button" className="google-pay-btn">Google Pay</button>
        </div>
      </div>
    </form>
  );
};

const Checkout: React.FC = () => {
  const [searchParams] = useSearchParams();
  const planId = searchParams.get('plan') || 'vip_monthly';

  const [promoCode, setPromoCode] = useState('');
  const [appliedPromo, setAppliedPromo] = useState<string | null>(null);
  const [discount, setDiscount] = useState(0);
  const [promoError, setPromoError] = useState<string | null>(null);

  const [applyPromoCode] = useApplyPromoCodeMutation();

  const handleApplyPromo = async () => {
    if (!promoCode.trim()) return;

    setPromoError(null);

    try {
      const result = await applyPromoCode(promoCode).unwrap();
      if (result.valid) {
        setAppliedPromo(promoCode);
        setDiscount(result.discount);
      } else {
        setPromoError('Invalid promo code');
      }
    } catch (err) {
      setPromoError('Failed to apply promo code');
    }
  };

  return (
    <div className="checkout-page">
      <header className="checkout-header">
        <button onClick={() => window.history.back()} className="back-btn">
          ← Back
        </button>
        <h1>Checkout</h1>
      </header>

      {/* Promo Code Section */}
      <div className="promo-section">
        <p>Have a promo code?</p>
        <div className="promo-input-group">
          <input
            type="text"
            value={promoCode}
            onChange={(e) => setPromoCode(e.target.value.toUpperCase())}
            placeholder="Enter code..."
            disabled={!!appliedPromo}
          />
          <button
            onClick={handleApplyPromo}
            disabled={!!appliedPromo}
          >
            {appliedPromo ? 'Applied ✓' : 'Apply'}
          </button>
        </div>
        {promoError && <p className="promo-error">{promoError}</p>}
      </div>

      {/* Stripe Elements */}
      <Elements stripe={stripePromise}>
        <CheckoutForm
          planId={planId}
          promoCode={appliedPromo || undefined}
          discount={discount}
        />
      </Elements>
    </div>
  );
};

export default Checkout;
```

---

## Screen 4: VIP Dashboard

**Route:** `/vip/dashboard`
**File:** `src/components/vip/VipDashboard.tsx`

### UI Layout (For Active VIP Members)

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]              VIP Dashboard                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │     👑 VIP MEMBER                                   │    │
│  │                                                     │    │
│  │     Member since: January 15, 2024                  │    │
│  │     Plan: VIP Yearly                                │    │
│  │     Next billing: January 15, 2025                  │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Your VIP Benefits                                          │
│                                                             │
│  ┌──────────────────┐ ┌──────────────────┐                 │
│  │ ✓ Unlimited      │ │ ✓ Profile        │                 │
│  │   Messages       │ │   Visitors       │                 │
│  │   Active         │ │   Active         │                 │
│  └──────────────────┘ └──────────────────┘                 │
│                                                             │
│  ┌──────────────────┐ ┌──────────────────┐                 │
│  │ ✓ No Ads         │ │ ✓ Unlimited      │                 │
│  │                  │ │   Learning       │                 │
│  │   Active         │ │   Active         │                 │
│  └──────────────────┘ └──────────────────┘                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Profile Boost                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │  🚀 Boost your profile to appear at the top!       │    │
│  │                                                     │    │
│  │  Boosts remaining this week: 1                      │    │
│  │  Last used: Never                                   │    │
│  │                                                     │    │
│  │                [Use Boost Now]                      │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Quick Links                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 👀 View Profile Visitors                        >   │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ 🎯 Use Advanced Filters                         >   │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ 📍 Find Nearby Users                            >   │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ ⚙️ Manage Subscription                          >   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Usage This Month                                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Messages sent          │ 1,234  │ Unlimited         │    │
│  │ Profiles viewed        │   456  │ Unlimited         │    │
│  │ Lessons completed      │    23  │ Unlimited         │    │
│  │ Words learned          │   189  │ Unlimited         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 5: Manage Subscription

**Route:** `/vip/manage`
**File:** `src/components/vip/ManageSubscription.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]           Manage Subscription                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Current Plan                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │  👑 VIP Yearly                                      │    │
│  │                                                     │    │
│  │  $79.99/year (billed annually)                      │    │
│  │                                                     │    │
│  │  Status: Active                                     │    │
│  │  Started: January 15, 2024                          │    │
│  │  Renews: January 15, 2025                           │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Payment Method                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  💳 •••• •••• •••• 4242                             │    │
│  │  Expires: 12/2025                                   │    │
│  │                                                     │    │
│  │  [Change] [Remove]                                  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [+ Add Payment Method]                                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Billing History                                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Jan 15, 2024  │ VIP Yearly    │ $79.99  │ [PDF]   │    │
│  │  Jan 15, 2023  │ VIP Yearly    │ $79.99  │ [PDF]   │    │
│  │  Jan 15, 2022  │ VIP Monthly   │ $9.99   │ [PDF]   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [View All Invoices]                                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Change Plan                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Switch to Monthly ($9.99/month)                    │    │
│  │  Change takes effect on your next billing date      │    │
│  │                                    [Change Plan]    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │  [Cancel Subscription]                     (Red)    │    │
│  │                                                     │    │
│  │  You'll keep VIP access until Jan 15, 2025         │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Cancel Modal

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                  We're sad to see you go 😢                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Before you go, here's what you'll lose:                    │
│                                                             │
│  ❌ Unlimited messages                                      │
│  ❌ See who viewed your profile                             │
│  ❌ Advanced search filters                                 │
│  ❌ Ad-free experience                                      │
│  ❌ VIP badge                                               │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Why are you cancelling? (optional)                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ○ Too expensive                                     │    │
│  │ ○ Not using enough                                  │    │
│  │ ○ Missing features I need                           │    │
│  │ ○ Technical issues                                  │    │
│  │ ○ Other                                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Feedback (optional)                                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Special Offer: Stay for 50% off your next month!          │
│                                                             │
│  [Accept Offer & Stay]                                      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Keep My VIP]           [Cancel Subscription]              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## VIP Feature Gates

### FeatureGate Component

```typescript
// components/FeatureGate.tsx
import React from 'react';
import { useSelector } from 'react-redux';
import { useGetMyVipStatusQuery, useGetUsageStatsQuery } from '../../store/slices/vipSlice';
import { VipFeature, FREE_LIMITS } from '../utils/vipFeatures';
import UpgradePrompt from './UpgradePrompt';
import { RootState } from '../../store';

interface FeatureGateProps {
  feature: VipFeature;
  limitKey?: string; // For features with usage limits
  children: React.ReactNode;
  fallback?: React.ReactNode;
  showUpgradePrompt?: boolean;
}

export const FeatureGate: React.FC<FeatureGateProps> = ({
  feature,
  limitKey,
  children,
  fallback,
  showUpgradePrompt = true,
}) => {
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const { data: vipStatus } = useGetMyVipStatusQuery(undefined, {
    skip: !userInfo?.token,
  });
  const { data: usageStats } = useGetUsageStatsQuery(undefined, {
    skip: !userInfo?.token,
  });

  const isVip = vipStatus?.data?.isVIP;

  // Check if feature is available
  const hasAccess = () => {
    // VIP has full access
    if (isVip) return true;

    // Check usage limits for free users
    if (limitKey && usageStats?.data) {
      const currentUsage = usageStats.data[limitKey] || 0;
      const limit = FREE_LIMITS[limitKey];
      return currentUsage < limit;
    }

    // Default deny for VIP-only features
    return false;
  };

  if (hasAccess()) {
    return <>{children}</>;
  }

  if (fallback) {
    return <>{fallback}</>;
  }

  if (showUpgradePrompt) {
    return <UpgradePrompt feature={feature} />;
  }

  return null;
};

// Hook for checking feature access
export const useFeatureAccess = (feature: VipFeature, limitKey?: string) => {
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const { data: vipStatus } = useGetMyVipStatusQuery(undefined, {
    skip: !userInfo?.token,
  });
  const { data: usageStats } = useGetUsageStatsQuery(undefined, {
    skip: !userInfo?.token,
  });

  const isVip = vipStatus?.data?.isVIP;

  const checkAccess = (): { hasAccess: boolean; remaining?: number; limit?: number } => {
    if (isVip) {
      return { hasAccess: true };
    }

    if (limitKey && usageStats?.data) {
      const currentUsage = usageStats.data[limitKey] || 0;
      const limit = FREE_LIMITS[limitKey];
      return {
        hasAccess: currentUsage < limit,
        remaining: Math.max(0, limit - currentUsage),
        limit,
      };
    }

    return { hasAccess: false };
  };

  return {
    isVip,
    ...checkAccess(),
  };
};
```

### Usage Examples

```typescript
// Example 1: Gate entire feature
<FeatureGate feature={VipFeature.SEE_PROFILE_VISITORS}>
  <ProfileVisitorsList />
</FeatureGate>

// Example 2: Gate with usage limit
<FeatureGate
  feature={VipFeature.UNLIMITED_MESSAGES}
  limitKey="messages_per_day"
>
  <SendMessageButton />
</FeatureGate>

// Example 3: Custom fallback
<FeatureGate
  feature={VipFeature.NEARBY_USERS}
  fallback={<NearbyUsersPreview />}
>
  <NearbyUsersList />
</FeatureGate>

// Example 4: Using the hook
const SendMessageButton = () => {
  const { hasAccess, remaining, limit } = useFeatureAccess(
    VipFeature.UNLIMITED_MESSAGES,
    'messages_per_day'
  );

  if (!hasAccess) {
    return (
      <button disabled>
        Daily limit reached. Upgrade to VIP!
      </button>
    );
  }

  return (
    <button onClick={handleSend}>
      Send Message {!isVip && `(${remaining}/${limit} left today)`}
    </button>
  );
};
```

### UpgradePrompt Component

```typescript
// components/UpgradePrompt.tsx
import React from 'react';
import { Link } from 'react-router-dom';
import { VipFeature } from '../utils/vipFeatures';
import './UpgradePrompt.scss';

interface UpgradePromptProps {
  feature: VipFeature;
  variant?: 'inline' | 'modal' | 'banner';
  onClose?: () => void;
}

const FEATURE_MESSAGES: Record<VipFeature, { title: string; description: string }> = {
  [VipFeature.SEE_PROFILE_VISITORS]: {
    title: 'See Who Viewed Your Profile',
    description: 'Upgrade to VIP to see who\'s interested in you!',
  },
  [VipFeature.UNLIMITED_MESSAGES]: {
    title: 'Unlimited Messages',
    description: 'Send as many messages as you want with VIP!',
  },
  [VipFeature.NEARBY_USERS]: {
    title: 'Find Nearby Users',
    description: 'Discover language partners near you with VIP!',
  },
  [VipFeature.ADVANCED_FILTERS]: {
    title: 'Advanced Filters',
    description: 'Find your perfect match with advanced search filters!',
  },
  // ... add all features
};

const UpgradePrompt: React.FC<UpgradePromptProps> = ({
  feature,
  variant = 'inline',
  onClose,
}) => {
  const message = FEATURE_MESSAGES[feature] || {
    title: 'VIP Feature',
    description: 'Upgrade to VIP to unlock this feature!',
  };

  if (variant === 'inline') {
    return (
      <div className="upgrade-prompt inline">
        <div className="prompt-icon">👑</div>
        <div className="prompt-content">
          <h4>{message.title}</h4>
          <p>{message.description}</p>
        </div>
        <Link to="/vip" className="upgrade-btn">
          Upgrade
        </Link>
      </div>
    );
  }

  if (variant === 'banner') {
    return (
      <div className="upgrade-prompt banner">
        <span className="prompt-icon">👑</span>
        <span className="prompt-text">{message.description}</span>
        <Link to="/vip" className="upgrade-btn">
          Get VIP
        </Link>
        {onClose && (
          <button className="close-btn" onClick={onClose}>×</button>
        )}
      </div>
    );
  }

  // Modal variant
  return (
    <div className="upgrade-prompt-modal-overlay">
      <div className="upgrade-prompt modal">
        <button className="close-btn" onClick={onClose}>×</button>
        <div className="prompt-icon large">👑</div>
        <h3>{message.title}</h3>
        <p>{message.description}</p>
        <div className="modal-actions">
          <button className="cancel-btn" onClick={onClose}>
            Maybe Later
          </button>
          <Link to="/vip" className="upgrade-btn primary">
            Upgrade to VIP
          </Link>
        </div>
      </div>
    </div>
  );
};

export default UpgradePrompt;
```

---

## VIP Badges & Indicators

### VipBadge Component

```typescript
// components/VipBadge.tsx
import React from 'react';
import './VipBadge.scss';

interface VipBadgeProps {
  type?: 'icon' | 'label' | 'full';
  size?: 'small' | 'medium' | 'large';
  plan?: 'monthly' | 'yearly';
}

const VipBadge: React.FC<VipBadgeProps> = ({
  type = 'icon',
  size = 'medium',
  plan,
}) => {
  if (type === 'icon') {
    return (
      <span className={`vip-badge icon ${size}`} title="VIP Member">
        👑
      </span>
    );
  }

  if (type === 'label') {
    return (
      <span className={`vip-badge label ${size}`}>
        VIP
      </span>
    );
  }

  // Full badge
  return (
    <span className={`vip-badge full ${size} ${plan || ''}`}>
      👑 VIP {plan === 'yearly' ? '(Yearly)' : ''}
    </span>
  );
};

export default VipBadge;
```

### SCSS Styles

```scss
// VipBadge.scss
.vip-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;

  &.icon {
    &.small { font-size: 12px; }
    &.medium { font-size: 16px; }
    &.large { font-size: 24px; }
  }

  &.label {
    background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
    color: white;
    font-weight: 700;
    border-radius: 4px;

    &.small {
      font-size: 10px;
      padding: 2px 4px;
    }
    &.medium {
      font-size: 12px;
      padding: 3px 6px;
    }
    &.large {
      font-size: 14px;
      padding: 4px 8px;
    }
  }

  &.full {
    background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
    color: white;
    font-weight: 600;
    border-radius: 20px;
    gap: 4px;

    &.small {
      font-size: 11px;
      padding: 4px 8px;
    }
    &.medium {
      font-size: 13px;
      padding: 6px 12px;
    }
    &.large {
      font-size: 15px;
      padding: 8px 16px;
    }

    &.yearly {
      background: linear-gradient(135deg, #7C4DFF 0%, #3F1DCB 100%);
    }
  }
}
```

### Usage in User Components

```typescript
// In user profile, community card, etc.
<div className="user-card">
  <img src={user.photo} alt={user.name} />
  <div className="user-info">
    <span className="user-name">
      {user.name}
      {user.isVIP && <VipBadge type="icon" size="small" />}
    </span>
  </div>
</div>

// In profile header
<div className="profile-header">
  <h1>{user.name}</h1>
  {user.isVIP && (
    <VipBadge type="full" size="medium" plan={user.vipPlan} />
  )}
</div>
```

---

## State Management

### VIP Hook

```typescript
// hooks/useVipStatus.ts
import { useSelector } from 'react-redux';
import { useGetMyVipStatusQuery, useGetSubscriptionQuery } from '../store/slices/vipSlice';
import { RootState } from '../store';

interface VipStatus {
  isVip: boolean;
  isLoading: boolean;
  plan?: 'monthly' | 'yearly';
  expiresAt?: Date;
  isExpiringSoon: boolean; // within 7 days
  isCancelled: boolean;
  features: string[];
}

export const useVipStatus = (): VipStatus => {
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);

  const { data: vipData, isLoading: vipLoading } = useGetMyVipStatusQuery(undefined, {
    skip: !userInfo?.token,
  });

  const { data: subData, isLoading: subLoading } = useGetSubscriptionQuery(undefined, {
    skip: !userInfo?.token,
  });

  const isLoading = vipLoading || subLoading;
  const isVip = vipData?.data?.isVIP || false;

  let expiresAt: Date | undefined;
  let isExpiringSoon = false;
  let isCancelled = false;

  if (subData?.data) {
    expiresAt = new Date(subData.data.currentPeriodEnd);
    isCancelled = subData.data.cancelAtPeriodEnd;

    const daysUntilExpiry = Math.ceil(
      (expiresAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    isExpiringSoon = daysUntilExpiry <= 7;
  }

  return {
    isVip,
    isLoading,
    plan: vipData?.data?.plan,
    expiresAt,
    isExpiringSoon,
    isCancelled,
    features: vipData?.data?.features || [],
  };
};
```

---

## Payment Integration

### Stripe Setup

```typescript
// src/lib/stripe.ts
import { loadStripe, Stripe } from '@stripe/stripe-js';

let stripePromise: Promise<Stripe | null>;

export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(process.env.REACT_APP_STRIPE_PUBLIC_KEY!);
  }
  return stripePromise;
};
```

### Environment Variables

```env
# .env
REACT_APP_STRIPE_PUBLIC_KEY=pk_test_xxxxx
```

### Payment Success Page

```typescript
// VipSuccess.tsx
import React, { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useVerifyPaymentMutation } from '../../store/slices/vipSlice';
import confetti from 'canvas-confetti';

const VipSuccess: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const sessionId = searchParams.get('session_id');

  const [verifyPayment, { isLoading, isSuccess, isError }] = useVerifyPaymentMutation();

  useEffect(() => {
    if (sessionId) {
      verifyPayment(sessionId);
    }
  }, [sessionId, verifyPayment]);

  useEffect(() => {
    if (isSuccess) {
      // Celebration animation
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
      });
    }
  }, [isSuccess]);

  if (isLoading) {
    return (
      <div className="vip-success loading">
        <div className="spinner" />
        <p>Activating your VIP subscription...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="vip-success error">
        <h1>Something went wrong</h1>
        <p>We couldn't verify your payment. Please contact support.</p>
        <button onClick={() => navigate('/support')}>Contact Support</button>
      </div>
    );
  }

  return (
    <div className="vip-success">
      <div className="success-content">
        <span className="success-icon">🎉</span>
        <h1>Welcome to VIP!</h1>
        <p>Your subscription is now active.</p>

        <div className="next-steps">
          <h3>What's next?</h3>
          <ul>
            <li>✓ Enjoy unlimited messages</li>
            <li>✓ See who viewed your profile</li>
            <li>✓ Use advanced filters</li>
            <li>✓ Learn without limits</li>
          </ul>
        </div>

        <div className="actions">
          <button onClick={() => navigate('/vip/dashboard')} className="primary">
            Go to VIP Dashboard
          </button>
          <button onClick={() => navigate('/community')} className="secondary">
            Explore Community
          </button>
        </div>
      </div>
    </div>
  );
};

export default VipSuccess;
```

---

## Components Library

### Summary of All VIP Components

```typescript
// Plan & Pricing
PlanCard.tsx              // Single plan display
PlanSelection.tsx         // Plan chooser
FeatureComparison.tsx     // Free vs VIP table
PricingCalculator.tsx     // Show savings

// Checkout
Checkout.tsx              // Payment form
PaymentMethod.tsx         // Card display/management
PromoCodeInput.tsx        // Coupon field

// VIP Dashboard
VipDashboard.tsx          // Member dashboard
VipBenefits.tsx           // Active benefits list
ProfileBoost.tsx          // Boost feature
UsageStats.tsx            // Usage display

// Subscription Management
ManageSubscription.tsx    // Settings page
BillingHistory.tsx        // Past payments
CancelModal.tsx           // Cancellation flow
ChangePlanModal.tsx       // Switch plans

// Gates & Prompts
FeatureGate.tsx           // Access wrapper
UpgradePrompt.tsx         // Upgrade CTA
LimitIndicator.tsx        // Show remaining
VipBadge.tsx              // Member badge

// Success/Error
VipSuccess.tsx            // Payment success
VipError.tsx              // Payment error
```

---

## Styling Guidelines

### VIP Colors

```scss
// _vip-colors.scss

// Gold theme (main VIP)
$vip-gold: #FFD700;
$vip-gold-light: #FFEB3B;
$vip-gold-dark: #FFA500;
$vip-gradient: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);

// Purple theme (yearly/premium)
$vip-purple: #7C4DFF;
$vip-purple-light: #B47CFF;
$vip-purple-dark: #3F1DCB;
$vip-yearly-gradient: linear-gradient(135deg, #7C4DFF 0%, #3F1DCB 100%);

// Status colors
$vip-active: #4CAF50;
$vip-expiring: #FF9800;
$vip-cancelled: #9E9E9E;
$vip-error: #E53935;
```

### Common Styles

```scss
// _vip-common.scss

.vip-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  padding: 24px;
}

.vip-button {
  background: $vip-gradient;
  color: white;
  font-weight: 600;
  border: none;
  border-radius: 12px;
  padding: 16px 32px;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(255, 215, 0, 0.4);
  }

  &.secondary {
    background: white;
    color: $vip-gold-dark;
    border: 2px solid $vip-gold;
  }
}

.vip-highlight {
  background: linear-gradient(135deg, rgba(255, 215, 0, 0.1) 0%, rgba(255, 165, 0, 0.1) 100%);
  border: 2px solid $vip-gold;
}
```

---

## Testing Checklist

### VIP Landing
- [ ] Benefits display correctly
- [ ] Feature comparison accurate
- [ ] Plan cards show correct prices
- [ ] CTA buttons navigate properly
- [ ] FAQ accordion works
- [ ] Redirects VIP users to dashboard

### Plan Selection
- [ ] Both plans display
- [ ] Prices are correct
- [ ] Savings calculated properly
- [ ] Promo code validation works
- [ ] Promo code applies discount

### Checkout
- [ ] Stripe Elements loads
- [ ] Card validation works
- [ ] Error messages display
- [ ] Payment processes correctly
- [ ] Success redirect works
- [ ] Alternative payments work

### VIP Dashboard
- [ ] Status displays correctly
- [ ] Benefits list accurate
- [ ] Profile boost works
- [ ] Usage stats update
- [ ] Quick links navigate

### Manage Subscription
- [ ] Current plan shows
- [ ] Payment method displays
- [ ] Change plan works
- [ ] Cancel flow works
- [ ] Reactivation works
- [ ] Billing history loads

### Feature Gates
- [ ] VIP features accessible to VIP
- [ ] Free limits enforced
- [ ] Upgrade prompts show
- [ ] Usage counters accurate
- [ ] Gates update on status change

---

## Routes Configuration

```typescript
// Add to AppRouter.tsx
const vipRoutes = [
  { path: '/vip', element: <VipLanding /> },
  { path: '/vip/plans', element: <PlanSelection /> },
  { path: '/vip/checkout', element: <Checkout /> },
  { path: '/vip/success', element: <VipSuccess /> },
  { path: '/vip/dashboard', element: <VipDashboard /> },
  { path: '/vip/manage', element: <ManageSubscription /> },
  { path: '/vip/features', element: <FeatureComparison /> },
];
```

---

## Contact

For questions about VIP implementation, contact the development team.
