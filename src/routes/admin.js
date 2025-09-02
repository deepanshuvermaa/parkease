const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, requireAdmin } = require('../middleware/auth');

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(requireAdmin);

// Dashboard and statistics
router.get('/dashboard', adminController.getDashboard);
router.get('/stats', adminController.getStatistics);
router.get('/reports', adminController.generateReport);

// User management
router.get('/users', adminController.getUsers);
router.put('/users/:userId/status', adminController.updateUserStatus);
router.delete('/users/:userId', adminController.deleteUser);

// Device management
router.get('/devices', adminController.getActiveDevices);
router.post('/force-logout', adminController.forceLogout);
router.post('/force-logout-all', adminController.forceLogoutAll);

// System settings
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);

// Audit logs
router.get('/audit-logs', adminController.getAuditLogs);

// ParkEase specific endpoints for admin panel
router.get('/parkease/stats', adminController.getParkeaseStats);
router.get('/parkease/activity', adminController.getRecentActivity);
router.post('/parkease/broadcast', adminController.broadcastMessage);
router.post('/parkease/clear-cache', adminController.clearCache);

module.exports = router;