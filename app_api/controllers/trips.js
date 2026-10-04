const mongoose = require('mongoose');
const Trip = require('../models/travlr'); // registers the model
const Model = mongoose.model('trips');

// GET: /trips - lists all trips
const tripsList = async (req, res) => {
  try {
    const q = await Model.find({}).exec();
    if (!q || q.length === 0) {
      return res.status(404).json({ message: 'No trips found' });
    }
    return res.status(200).json(q);
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// GET: /trips/:tripCode - returns a single trip
const tripsFindByCode = async (req, res) => {
  try {
    const q = await Model.find({ code: req.params.tripCode }).exec();
    if (!q || q.length === 0) {
      return res.status(404).json({ message: `Trip ${req.params.tripCode} not found` });
    }
    return res.status(200).json(q);
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

module.exports = { tripsList, tripsFindByCode };