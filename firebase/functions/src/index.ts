import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const orderData = snapshot.data();
    functions.logger.info("New order created", { orderId: context.params.orderId, data: orderData });
    
    // Logic for notifying vendor or assigning driver could go here.
    return null;
  });

export const onChatMessageCreated = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    functions.logger.info("New chat message", { 
      chatId: context.params.chatId, 
      messageId: context.params.messageId, 
      data: messageData 
    });

    // Logic for AI response or moderation could go here.
    return null;
  });
