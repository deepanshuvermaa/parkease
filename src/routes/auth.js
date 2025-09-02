const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validateLogin, validateGuestSignup, validateRefresh } = require('../middleware/validation');

// Public routes
router.post('/login', validateLogin, authController.login);
router.post('/guest-signup', validateGuestSignup, authController.guestSignup);
router.post('/refresh', validateRefresh, authController.refresh);

// Protected routes
router.post('/logout', authenticate, authController.logout);
router.get('/sessions', authenticate, authController.getSessions);
router.delete('/sessions/:sessionId', authenticate, authController.forceLogout);

module.exports = router;