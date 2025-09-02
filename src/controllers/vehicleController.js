const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

// Get all vehicles
exports.getVehicles = async (req, res) => {
  try {
    const { userId, role } = req.user;
    const { active, from, to, limit = 100, offset = 0 } = req.query;
    
    let query = `
      SELECT v.*, u.full_name as operator_name 
      FROM vehicles v
      LEFT JOIN users u ON v.operator_id = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;
    
    // Filter by operator if not admin
    if (role !== 'admin') {
      query += ` AND v.operator_id = $${paramIndex++}`;
      params.push(userId);
    }
    
    // Filter by active status
    if (active === 'true') {
      query += ` AND v.exit_time IS NULL`;
    } else if (active === 'false') {
      query += ` AND v.exit_time IS NOT NULL`;
    }
    
    // Filter by date range
    if (from) {
      query += ` AND v.entry_time >= $${paramIndex++}`;
      params.push(from);
    }
    if (to) {
      query += ` AND v.entry_time <= $${paramIndex++}`;
      params.push(to);
    }
    
    query += ` ORDER BY v.entry_time DESC LIMIT $${paramIndex++} OFFSET $${paramIndex}`;
    params.push(limit, offset);
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      vehicles: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Get vehicles error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Add new vehicle
exports.addVehicle = async (req, res) => {
  try {
    const { userId } = req.user;
    const {
      ticketId,
      vehicleNumber,
      vehicleType,
      entryTime,
      rate,
      ownerName,
      phoneNumber
    } = req.body;
    
    // Check if ticket ID already exists
    const existingTicket = await db.query(
      'SELECT id FROM vehicles WHERE ticket_id = $1',
      [ticketId]
    );
    
    if (existingTicket.rows.length > 0) {
      return res.status(400).json({ error: 'Ticket ID already exists' });
    }
    
    const result = await db.query(
      `INSERT INTO vehicles 
       (id, ticket_id, vehicle_number, vehicle_type, entry_time, rate, 
        owner_name, phone_number, operator_id, created_at, synced_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        uuidv4(),
        ticketId,
        vehicleNumber,
        vehicleType,
        entryTime || new Date(),
        rate,
        ownerName,
        phoneNumber,
        userId
      ]
    );
    
    const vehicle = result.rows[0];
    
    // Emit real-time update
    req.io?.to(`user_${userId}`).emit('vehicle_added', vehicle);
    
    res.json({
      success: true,
      vehicle,
      message: 'Vehicle entry recorded successfully'
    });
  } catch (error) {
    console.error('Add vehicle error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update vehicle (exit)
exports.updateVehicle = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, role } = req.user;
    const { exitTime, totalAmount, isPaid, paymentMethod } = req.body;
    
    // Check ownership
    let query = 'SELECT * FROM vehicles WHERE id = $1';
    const params = [id];
    
    if (role !== 'admin') {
      query += ' AND operator_id = $2';
      params.push(userId);
    }
    
    const vehicleResult = await db.query(query, params);
    
    if (vehicleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }
    
    // Update vehicle
    const updateResult = await db.query(
      `UPDATE vehicles 
       SET exit_time = $1, total_amount = $2, is_paid = $3, 
           payment_method = $4, synced_at = CURRENT_TIMESTAMP
       WHERE id = $5
       RETURNING *`,
      [exitTime || new Date(), totalAmount, isPaid, paymentMethod, id]
    );
    
    const vehicle = updateResult.rows[0];
    
    // Emit real-time update
    req.io?.to(`user_${userId}`).emit('vehicle_updated', vehicle);
    
    res.json({
      success: true,
      vehicle,
      message: 'Vehicle exit recorded successfully'
    });
  } catch (error) {
    console.error('Update vehicle error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Bulk sync vehicles
exports.syncVehicles = async (req, res) => {
  try {
    const { userId } = req.user;
    const { vehicles, lastSyncTime } = req.body;
    
    const syncedVehicles = [];
    const errors = [];
    
    // Start transaction
    await db.query('BEGIN');
    
    try {
      for (const vehicle of vehicles) {
        try {
          // Upsert vehicle
          const result = await db.query(
            `INSERT INTO vehicles 
             (id, ticket_id, vehicle_number, vehicle_type, entry_time, exit_time,
              rate, total_amount, is_paid, payment_method, owner_name, phone_number,
              operator_id, created_at, synced_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, CURRENT_TIMESTAMP)
             ON CONFLICT (ticket_id) 
             DO UPDATE SET
               exit_time = EXCLUDED.exit_time,
               total_amount = EXCLUDED.total_amount,
               is_paid = EXCLUDED.is_paid,
               payment_method = EXCLUDED.payment_method,
               synced_at = CURRENT_TIMESTAMP
             RETURNING *`,
            [
              vehicle.id || uuidv4(),
              vehicle.ticketId,
              vehicle.vehicleNumber,
              vehicle.vehicleType,
              vehicle.entryTime,
              vehicle.exitTime,
              vehicle.rate,
              vehicle.totalAmount,
              vehicle.isPaid,
              vehicle.paymentMethod,
              vehicle.ownerName,
              vehicle.phoneNumber,
              userId,
              vehicle.createdAt || new Date()
            ]
          );
          
          syncedVehicles.push(result.rows[0]);
        } catch (vehicleError) {
          errors.push({
            ticketId: vehicle.ticketId,
            error: vehicleError.message
          });
        }
      }
      
      // Get new/updated vehicles since last sync
      let serverUpdates = [];
      if (lastSyncTime) {
        const updatesResult = await db.query(
          `SELECT * FROM vehicles 
           WHERE operator_id = $1 AND synced_at > $2
           ORDER BY synced_at DESC`,
          [userId, lastSyncTime]
        );
        serverUpdates = updatesResult.rows;
      }
      
      await db.query('COMMIT');
      
      res.json({
        success: true,
        syncedCount: syncedVehicles.length,
        errorCount: errors.length,
        syncedVehicles,
        serverUpdates,
        errors: errors.length > 0 ? errors : undefined,
        syncTime: new Date().toISOString()
      });
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    }
  } catch (error) {
    console.error('Sync vehicles error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get active vehicles count
exports.getActiveCount = async (req, res) => {
  try {
    const { userId, role } = req.user;
    
    let query = 'SELECT COUNT(*) as count FROM vehicles WHERE exit_time IS NULL';
    const params = [];
    
    if (role !== 'admin') {
      query += ' AND operator_id = $1';
      params.push(userId);
    }
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      count: parseInt(result.rows[0].count)
    });
  } catch (error) {
    console.error('Get active count error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete vehicle
exports.deleteVehicle = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, role } = req.user;
    
    let query = 'DELETE FROM vehicles WHERE id = $1';
    const params = [id];
    
    if (role !== 'admin') {
      query += ' AND operator_id = $2';
      params.push(userId);
    }
    
    query += ' RETURNING *';
    
    const result = await db.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }
    
    res.json({
      success: true,
      message: 'Vehicle deleted successfully'
    });
  } catch (error) {
    console.error('Delete vehicle error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};