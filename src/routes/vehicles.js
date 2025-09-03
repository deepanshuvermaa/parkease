const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');
const { authenticate } = require('../middleware/auth');
const { validateVehicle, validateSync } = require('../middleware/validation');

// All routes require authentication
router.use(authenticate);

// Vehicle routes
router.get('/', vehicleController.getVehicles);
router.post('/', validateVehicle, vehicleController.addVehicle);
router.put('/:id', validateVehicle, vehicleController.updateVehicle);
router.delete('/:id', vehicleController.deleteVehicle);

// Sync route
router.post('/sync', validateSync, vehicleController.syncVehicles);

// Stats
router.get('/active/count', vehicleController.getActiveCount);

module.exports = router;