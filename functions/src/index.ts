import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();

export const extractTasks = onCall(
  {
    secrets: ["GEMINI_KEY"],
  },
  async (request) => {

    // 🔐 Auth check
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const rawText = request.data?.text;

    // 📥 Input validation
    if (!rawText || typeof rawText !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Valid text input required"
      );
    }

    try {
      // 🔑 Initialize Gemini using injected secret
      const genAI = new GoogleGenerativeAI(
        process.env.GEMINI_KEY as string
      );

      const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
      });

      const prompt = `
Return ONLY valid JSON in this exact format:

{
  "tasks": [
    {
      "title": "string",
      "reminderTimestamp": "ISO8601 or null",
      "priority": "low | medium | high"
    }
  ]
}

User speech:
"${rawText}"
`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // 🧼 Clean possible markdown wrapping
      const cleaned = text
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();

      const parsed = JSON.parse(cleaned);

      // 🧠 Basic structure validation
      if (!parsed.tasks || !Array.isArray(parsed.tasks)) {
        throw new Error("Invalid AI response structure");
      }

      return {
        success: true,
        data: parsed,
      };

    } catch (error) {
      console.error("Gemini error:", error);

      throw new HttpsError(
        "internal",
        "Task extraction failed"
      );
    }
  }
);