const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// User profile
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.put('/password', userController.changePassword);

// Subscription
router.get('/subscription', userController.getSubscription);
router.post('/subscription/upgrade', userController.upgradeSubscription);

module.exports = router;