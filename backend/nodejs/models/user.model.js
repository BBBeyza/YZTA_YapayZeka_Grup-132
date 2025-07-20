import db from "../firebase.js";
import { collection, doc, setDoc, getDoc } from "firebase/firestore";

const usersCollection = collection(db, "users");

export const createUserInDB = async (userData) => {
  const userRef = doc(usersCollection, userData.email);
  await setDoc(userRef, userData);
};

export const getUserByEmail = async (email) => {
  const userRef = doc(usersCollection, email);
  const snap = await getDoc(userRef);
  return snap.exists() ? snap.data() : null;
};
