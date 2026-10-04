   const Mongoose = require('./db');
   const Trip = require('./travlr');

   const runTest = async () => {
       const trips = await Trip.find({}).lean();
       console.log(`Found ${trips.length} trips:`);
       console.log(JSON.stringify(trips, null, 2));
       await Mongoose.connection.close();
       process.exit(0);
   };

   runTest();
   