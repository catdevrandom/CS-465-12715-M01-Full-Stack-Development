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

// POST: /trips - adds a new trip
const tripsAddTrip = async (req, res) => {
  try {
    const q = await Model.create({
      code: req.body.code,
      name: req.body.name,
      length: req.body.length,
      start: req.body.start,
      resort: req.body.resort,
      perPerson: req.body.perPerson,
      image: req.body.image,
      description: req.body.description
    });
    return res.status(201).json(q);
  } catch (err) {
    return res.status(400).json({ message: err.message });
  }
};

// PUT: /trips/:tripCode - updates a trip
const tripsUpdateTrip = async (req, res) => {
  try {
    const q = await Model.findOneAndUpdate(
      { code: req.params.tripCode },
      {
        code: req.body.code,
        name: req.body.name,
        length: req.body.length,
        start: req.body.start,
        resort: req.body.resort,
        perPerson: req.body.perPerson,
        image: req.body.image,
        description: req.body.description
      }
    ).exec();
    if (!q) {
      return res.status(404).json({ message: `Trip ${req.params.tripCode} not found` });
    }
    return res.status(201).json(q);
  } catch (err) {
    return res.status(400).json({ message: err.message });
  }
};

// DELETE: /trips/:tripCode - deletes a trip
const tripsDeleteTrip = async (req, res) => {
  try {
    const q = await Model.findOneAndDelete({ code: req.params.tripCode }).exec();
    if (!q) {
      return res.status(404).json({ message: `Trip ${req.params.tripCode} not found` });
    }
    return res.status(204).json(null);
  } catch (err) {
    return res.status(400).json({ message: err.message });
  }
};

module.exports = {
  tripsList,
  tripsFindByCode,
  tripsAddTrip,
  tripsUpdateTrip,
  tripsDeleteTrip
};