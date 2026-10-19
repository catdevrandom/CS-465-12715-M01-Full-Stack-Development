const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const User = require('../models/user');

passport.use(new LocalStrategy(
  { usernameField: 'email' },
  async (username, password, done) => {
    try {
      const user = await User.findOne({ email: username }).exec();
      if (!user) {
        return done(null, false, { message: 'Incorrect username.' });
      }
      if (!user.validPassword(password)) {
        return done(null, false, { message: 'Incorrect password.' });
      }
      return done(null, user);
    } catch (err) {
      console.error('PASSPORT ERROR:', err);
      return done(err);
    }
  }
));