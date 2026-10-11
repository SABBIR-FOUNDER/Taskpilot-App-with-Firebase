// Run only on a trusted computer. Never put Admin credentials in the Flutter app.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const [projectId, userId, taskId] = process.argv.slice(2);
const token = process.env.TASKPILOT_FCM_TOKEN;
if (!projectId || !userId || !taskId || !token || /[/]/.test(userId + taskId)) {
  console.error('Usage: TASKPILOT_FCM_TOKEN=<device token> npm run send -- <project-id> <user-uid> <task-id>');
  process.exit(1);
}
initializeApp({ credential: applicationDefault(), projectId });
try {
  const snapshot = await getFirestore().doc(`users/${userId}/tasks/${taskId}`).get();
  if (!snapshot.exists) throw new Error('Task not found for that user.');
  const task = snapshot.data();
  const high = task.priority === 'high';
  const messageId = await getMessaging().send({
    token,
    notification: { title: high ? 'High priority task' : 'Task update', body: `You have a task: ${task.title}` },
    data: { taskId, userId, priority: task.priority },
    android: { priority: 'high', notification: { channelId: high ? 'taskpilot_urgent' : 'taskpilot_tasks', icon: 'ic_notification', color: '#5262F3' } },
    apns: { payload: { aps: { sound: 'default' } } },
  });
  console.log(`FCM accepted the message: ${messageId}`);
  console.log('Confirm receipt on the target device; acceptance alone does not prove delivery.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
