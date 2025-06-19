/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Inicializácia admin SDK, ak ešte nie je inicializovaná
if (!admin.apps.length) {
  admin.initializeApp();
}

export const updateLastMessageOnMessageCreate = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // Ak je typ správy 'system', neaktualizujeme lastMessage
    if (messageData.type === "system") return;

    const chatId = event.params.chatId;
    const chatRef = admin.firestore().collection("chats").doc(chatId);

    // Pripravíme lastMessage objekt
    const lastMessage = {
      senderId: messageData.senderId,
      text: messageData.text,
      timestamp: messageData.timestamp,
      type: messageData.type,
      subtype: messageData.subtype,
    };

    await chatRef.set(
      {
        lastMessage,
        lastMessageAt: messageData.timestamp,
      },
      { merge: true }
    );
  }
);
