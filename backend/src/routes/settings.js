const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// User settings
router.get('/', settingsController.getSettings);
router.put('/', settingsController.updateSettings);
router.get('/:key', settingsController.getSetting);
router.put('/:key', settingsController.updateSetting);

module.exports = router;