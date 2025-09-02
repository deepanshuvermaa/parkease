const Joi = require('joi');

// Login validation
exports.validateLogin = (req, res, next) => {
  const schema = Joi.object({
    username: Joi.string().required(),
    password: Joi.string().required(),
    deviceId: Joi.string().required(),
    deviceName: Joi.string().optional(),
    devicePlatform: Joi.string().optional()
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};

// Guest signup validation
exports.validateGuestSignup = (req, res, next) => {
  const schema = Joi.object({
    deviceId: Joi.string().required(),
    deviceName: Joi.string().optional(),
    devicePlatform: Joi.string().optional()
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};

// Refresh token validation
exports.validateRefresh = (req, res, next) => {
  const schema = Joi.object({
    refreshToken: Joi.string().required()
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};

// Vehicle validation
exports.validateVehicle = (req, res, next) => {
  const schema = Joi.object({
    ticketId: Joi.string().required(),
    vehicleNumber: Joi.string().allow('', null),
    vehicleType: Joi.string().required(),
    entryTime: Joi.date().optional(),
    exitTime: Joi.date().optional(),
    rate: Joi.number().positive().required(),
    totalAmount: Joi.number().positive().optional(),
    isPaid: Joi.boolean().optional(),
    paymentMethod: Joi.string().optional(),
    ownerName: Joi.string().allow('', null),
    phoneNumber: Joi.string().allow('', null)
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};

// Sync validation
exports.validateSync = (req, res, next) => {
  const schema = Joi.object({
    vehicles: Joi.array().items(Joi.object({
      ticketId: Joi.string().required(),
      vehicleNumber: Joi.string().allow('', null),
      vehicleType: Joi.string().required(),
      entryTime: Joi.date().required(),
      exitTime: Joi.date().allow(null),
      rate: Joi.number().positive().required(),
      totalAmount: Joi.number().positive().allow(null),
      isPaid: Joi.boolean(),
      paymentMethod: Joi.string().allow('', null),
      ownerName: Joi.string().allow('', null),
      phoneNumber: Joi.string().allow('', null),
      createdAt: Joi.date().optional()
    })).required(),
    lastSyncTime: Joi.date().optional()
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};