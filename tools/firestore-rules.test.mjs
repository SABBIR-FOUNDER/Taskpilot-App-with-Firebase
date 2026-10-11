import { before, after, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
let env;
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-taskpilot',firestore:{rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8'),host:'127.0.0.1',port:8080}});});
after(async()=>{await env?.cleanup();});
beforeEach(async()=>{await env.clearFirestore();});
const data=()=>({title:'Finish assignment',description:'Test notifications',dueDate:Timestamp.fromDate(new Date('2026-12-01')),priority:'high',completed:false,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
const ref=(uid,owner=uid)=>doc(env.authenticatedContext(uid).firestore(),`users/${owner}/tasks/task-1`);
test('owner can create, read, update and delete',async()=>{
  const task=ref('alice');await assertSucceeds(setDoc(task,data()));await assertSucceeds(getDoc(task));
  await assertSucceeds(updateDoc(task,{completed:true,updatedAt:serverTimestamp()}));await assertSucceeds(deleteDoc(task));
});
test('another user cannot read, write, or delete',async()=>{
  await setDoc(ref('alice'),data());const other=ref('bob','alice');
  await assertFails(getDoc(other));await assertFails(setDoc(other,data()));await assertFails(deleteDoc(other));
});
test('unauthenticated clients cannot read or create',async()=>{
  const task=doc(env.unauthenticatedContext().firestore(),'users/alice/tasks/task-1');
  await assertFails(getDoc(task));await assertFails(setDoc(task,data()));
});
test('invalid priority, oversized title, and unexpected fields are rejected',async()=>{
  for(const changes of [{priority:'urgent'},{title:'x'.repeat(121)},{admin:true},{completed:'yes'},{title:''}]){
    await assertFails(setDoc(ref('alice'),{...data(),...changes}));
  }
});
test('created timestamp cannot be rewritten on update',async()=>{
  const task=ref('alice');await setDoc(task,data());
  await assertFails(updateDoc(task,{createdAt:Timestamp.fromMillis(0),updatedAt:serverTimestamp()}));
});
