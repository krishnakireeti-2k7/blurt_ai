# Technical Architecture README

## AI Voice Task App — System Design Specification (v1)

---

# 1. Overview

This document defines the technical architecture, technology choices, and system responsibilities for the AI Voice Task application.

The goal is to create a **production-ready mobile application** that converts spoken user input into structured tasks using AI processing, while maintaining scalability, security, and maintainability.

This document exists to:

* Provide context for developers
* Guide architectural decisions
* Enable AI tools to understand project structure
* Prevent ad-hoc technical drift

---

# 2. Core Technology Stack

## Frontend

* **Framework:** Flutter
* **Language:** Dart
* **State Management:** Riverpod
* **Speech Recognition:** On-device speech-to-text plugin

---

## Backend Platform

* **Platform:** Firebase

### Services Used

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions
* Firebase Cloud Messaging

---

## AI Processing

* External LLM API accessed via Cloud Functions
* API keys never exposed to client application

---

# 3. System Architecture

## High-Level Flow

```
User Speech
   ↓
On-device Speech Recognition
   ↓
Text sent to Cloud Function
   ↓
AI Task Extraction
   ↓
Structured response returned
   ↓
Saved to Firestore
   ↓
Reminder scheduling
   ↓
Push Notification (FCM)
```

---

## Component Responsibility Breakdown

### Flutter Client

Responsible for:

* User interaction
* Audio capture
* Speech transcription
* Displaying task UI
* Sending text to backend
* Rendering structured tasks
* Managing local UX state

Not responsible for:

* AI key storage
* Task parsing logic
* Secure processing
* Notification scheduling logic

---

### Cloud Functions

Acts as middleware layer.

Responsibilities:

* Validate requests
* Construct AI prompts
* Send request to AI API
* Parse/validate AI output
* Return structured JSON
* Prevent client key exposure

This layer centralizes intelligence logic.

---

### Firestore

Primary persistent storage.

Responsibilities:

* User data
* Task storage
* Metadata tracking
* Reminder timestamps

Chosen for:

* Realtime sync
* Flutter integration
* Scalability
* Simplicity

---

### Firebase Authentication

Manages:

* User identity
* Secure session management
* Account creation
* Login persistence

Initial providers:

* Email/password

Expandable later:

* Google Sign-In
* Apple Sign-In

---

### Firebase Cloud Messaging

Handles:

* Reminder notifications
* Background alerts

Triggered by:

* Scheduled events
* Backend logic

---

# 4. Data Model (Conceptual)

## Users Collection

Stores minimal profile metadata.

Example fields:

* userId
* createdAt
* preferences (future)
* notification settings (future)

---

## Tasks Collection

Each task document may include:

* userId
* rawSpeechText
* parsedTaskText
* priority
* pinned
* completed
* reminderTimestamp
* createdAt
* updatedAt
* groupingBucket (day/week/month)

Structure may evolve as AI output expands.

---

# 5. AI Processing Strategy

## Why Cloud Function Intermediation

Direct client-to-AI calls are avoided due to:

* API key exposure
* Abuse risk
* Billing vulnerability
* Security concerns

---

## Prompt Responsibility

Cloud Function will:

1. Receive transcription text
2. Format prompt
3. Request structured extraction
4. Enforce JSON schema response
5. Return sanitized result

---

## Response Expectations

AI should return structured output including:

* Extracted tasks
* Timing hints
* Reminder signals
* Confidence fallback handling

Strict parsing validation required.

---

# 6. Speech Recognition Strategy

## Initial Approach

* On-device recognition

Reasons:

* Faster iteration
* Lower cost
* Reduced latency
* Simpler architecture

---

## Future Upgrade Path

* Whisper / cloud transcription
* Hybrid fallback
* Quality improvements

This is intentionally deferred.

---

# 7. Security Principles

* No secret keys in client
* Auth required for DB access
* Firestore rules enforced
* Cloud Function validation layer
* Principle of minimal exposure

Security evolves with product maturity.

---

# 8. Scalability Considerations

Firebase allows:

* Horizontal scaling
* Load balancing
* Serverless compute expansion

System designed to grow without major rewrites.

---

# 9. Observability (Future Consideration)

Potential later additions:

* Error logging
* AI usage analytics
* Crash tracking
* Performance monitoring

Not required for v1 launch.

---

# 10. Development Philosophy

This architecture prioritizes:

* Speed of execution
* Production safety
* Simplicity
* Expandability
* Focus on AI product value

It intentionally avoids:

* Premature microservices
* Custom backend complexity
* Infrastructure-heavy design

---

# 11. Guiding Technical Question

When making technical decisions, ask:

> Does this improve the reliability or intelligence of the voice-to-task pipeline?

If not, reconsider implementation complexity.

---

END OF DOCUMENT
