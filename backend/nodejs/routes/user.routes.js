import express from "express";
import { verifyToken } from "../middleware/auth.middleware.js";

const router = express.Router();

// Sadece token geçerli ise çalışır
router.get("/profile", verifyToken, (req, res) => {
  res.status(200).json({
    message: `Hoş geldin, ${req.user.email}`,
  });
});

export default router;