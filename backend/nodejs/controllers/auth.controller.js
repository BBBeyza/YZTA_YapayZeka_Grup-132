import bcrypt from "bcryptjs";
import { createUserInDB, getUserByEmail } from "../models/user.model.js";

// Kullanıcı kaydı
export const register = async (req, res) => {
  const { fullName, email, password } = req.body;

  try {
    const existingUser = await getUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({ message: "Kullanıcı zaten var." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await createUserInDB({
      fullName,
      email,
      password: hashedPassword,
      createdAt: new Date(),
    });

    return res.status(201).json({ message: "Kayıt başarılı." });
  } catch (err) {
    return res.status(500).json({ message: "Sunucu hatası.", error: err.message });
  }
};

// Giriş kontrolü
export const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await getUserByEmail(email);
    if (!user) return res.status(404).json({ message: "Kullanıcı bulunamadı." });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: "Şifre hatalı." });

    // JWT token
    return res.status(200).json({ message: "Giriş başarılı." });
  } catch (err) {
    return res.status(500).json({ message: "Sunucu hatası.", error: err.message });
  }
};
