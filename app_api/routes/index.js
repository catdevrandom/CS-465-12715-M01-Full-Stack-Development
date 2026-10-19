const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const tripsController = require('../controllers/trips');
const authController = require('../controllers/authentication');

// Middleware: require a valid JWT in the Authorization header
function authenticateJWT(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (authHeader == null) {
    console.log('Auth header required but not present');
    return res.status(401).json({ message: 'Authorization header required' });
  }

  const parts = authHeader.split(' ');
  const token = parts[1];
  if (!token) {
    console.log('Null bearer token');
    return res.status(401).json({ message: 'Bearer token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, verified) => {
    if (err) {
      console.log('Token validation error');
      return res.status(401).json({ message: 'Token validation error' });
    }
    req.auth = verified;
    next(); // only continue when the token is valid
  });
}

// Public auth endpoints
router
  .route('/register')
  .post(authController.register);

router
  .route('/login')
  .post(authController.login);

// Trips: reads are public, writes require a token
router
  .route('/trips')
  .get(tripsController.tripsList)
  .post(authenticateJWT, tripsController.tripsAddTrip);

router
  .route('/trips/:tripCode')
  .get(tripsController.tripsFindByCode)
  .put(authenticateJWT, tripsController.tripsUpdateTrip)
  .delete(authenticateJWT, tripsController.tripsDeleteTrip);

module.exports = router;